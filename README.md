This project was designed to classify MNIST digits directly on hardware, Xilinx Zynq-7000 (Zc706) board using only PL. The main concept is the following: the **RISC-V CPU** sends commands to its 
**co-processor** (neural network accelerator) using the **RoCC interface**. 
<img width="5803" height="3169" alt="RISC-V CPU" src="https://github.com/user-attachments/assets/c1603628-0373-483c-bdfb-c406de57bce3" />

The combination of the open-source RISC-V CPU architecture and custom NN accelerator is a balance between flexibility for handling control flow and communation as well as hardwired extension for computational efficiency. 

## RoCC Interface

Because we care about minimizing latency (time per one image inference), the RoCC interface was chosen as a bridge between the accelerator and the processor as it takes only about 1-10 cycles 
to write the result (spoiler) directly to the register file. RoCC (Rocket Custom Coprocessor) is a protocol defined by the UC Berkeley Rocket chip generator for attaching custom accelerators inside the CPU pipeline. 
For this configuration, RISC-V fetches and decodes the custom instructions (e.g. R-type custom-0) and passes them together with register file values to the accelerator. In turnm the co-processor writes the inference result 
back to the CPU registers with no memory roundtrip, thus, posessing a property of "tightly-coupled". 

In contrast, such interfaces as AXI4, write the operands to SRAM first, then these are transmitted to the accelerator via DMA, taking about 50-500 extra cycles. The advantage of this configuration is compatibility with 
any type of CPU, while RoCC requires RISC-V with custom instructions.

In this implemenrtation, the RoCC bridge accepts 5 commands from the processor, defined by their unique funct7 and funct3 values (as it is done in usual R-type instructions):
+ SET_CONFIG ({funct7, funct3} = 10'b0000001_000) is used to define the location of a neuron for which we want to push new weights or bias values. For this we need to pass the layer_num and neuron_num in this
  layer as rs1 and rs2 registers, respectively.
+  PUSH_WEIGHT ({funct7, funct3} = 10'b0000001_001): as name suggests, we push the weights for this particular neuron defines by previous instruction.
+  PUSH_BIAS ({funct7, funct3} = 10'b0000001_010): similar to the weights.
+  READ_RESULT ({funct7, funct3} = 10'b0000001_011): the most important (and, in fact, the only one that was tested:)) instruction for this project, which sends a command to the co-processor to provide the inference result
  and place it to the register rd. After sending this instruction, the CPU waits (by stalling the program counter) when the result becomes valid and is written to the indicated register address.
+ SOFT_RSET ({funct7, funct3} = 10'b0000001_100): plays the same role as the push-button reset, but in software.

## Neural Network Accelerator (Co-processor)
### Private scratchpad memory
The accelerator has its own private scratchpad memory to where the input data is arriving serially via UART. Having a private scratchpad memory that is not mapped to the CPU's address space guarantees single-cycle reads
for the deterministic inference latency. A shared or cached memory would introduce variable access latency and require a coherence mechanism between the core and accelerator. In fact, the CPU does not need to have access 
to the input data, be it from UART (host PC) or ADC (sensor readings - future work). The CPU knows that it is dealing with MNIST digits (or strawberries of different ripeness, or slip detection, etc.), so it just needs to 
know whether the current input is "3" or "8", and then send commands to other modules, accordingly. This is the rationale behind having a privide to accelerator memory (the only one that needs input data). Preprocessing 
can be also implemented inside accelerator. 

### Input data (pixels)
The majority of time is taken by the UART sending pixel values to the scratchpad serially (~7.84ms per image at 100MHz). Since the UART data is transmitetd as 8-bit samples while the datapath operates on 16-bit 
fixed-point values, each sample is zero-extended and left-shifted into the Q1.15 format {1'b0, pixel, 7'b0}, mapping the 0–255 input range onto [0, 0.996). For example, if the inital pixel value was 8'b0100_0000 (8'd64),
then the corresponding input value would be 16'b0_0100_0000_0000000 (16'd8192). In Q1.15 format, this value equals to 8192 / 2^(fracNum) = 8192 / 2^15 = 0.25. 
The Q1.15 format was chosen for activations because the inputs to all layers lie in the range [0, 1). For hidden layers this follows from the sigmoid activation, whose output is bounded by construction; 
for the first layer it follows from the normalization applied when packing the sensor sample. A single integer bit is therefore sufficient. Since the datapath uses signed two's-complement arithmetic throughout,
this bit serves as the sign bit and remains zero for all activation values, leaving 15 bits of fractional resolution.

### Feedforward NN 
The proposed NN consists of input layer, 4 hidden layers (30-30-10-10), and an output. Each layer is implemented as an array of parallel neuron units, one per output neuron, each with a dedicated multiply-accumulate datapath and private weight memory. Inputs are broadcast to all neurons within a layer and consumed serially, one element per clock cycle; a layer completes after its full input vector has been streamed. Activations are serialized between layers by a finite state machine. Once the output layer has produced its ten activations, a hardmax stage selects the index of the largest value as the predicted digit, sequentially comparing the ten output activations. 

### Neuron 
Each neuron in the NN model has private memory that stores one pre-trained coefficient per input connection. All neurons within a layer perform their multiply-accumulate operation in the same cycle. Weights are either initialized from file at synthesis time or written at runtime through the RoCC interface. All arithmetic is performed in 16-bit two's complement fixed-point. 

**Weight quantization** is performed after training the model. To choose a fixed-point Qm.n format (where m is integer bits and n is fractional bits for a total word length of m + n bits), 1) we look at the absolute maximum value $W_{max} = max(|W_{min}|, |W_{max}|)$, 2) find the number of integer bits that accommodates this largest absolute value so that $2^{m-1} > W_{max}$, and 3) subtract the chosen integer bits m (including the sign bit) from the total hardware word length W (16-bit, in this case) to assign the remaining fractional (resolution) bits: n = W - m. In this model, the $W_{max}$ is |-6.519046366627739|, which means that we need at least 4 bits to represent this number in binary. Therefore, the number of fractional bits is 16-4=12. The Q-format for the weight quantization is Q4.12. 

The formula that was used to convert the weights into 16-bit two's-complement integers: $x_{int} = round(x_{real} \cdot 2^n)$, where $1/2^n$ (or $2^{-12}$) is the resolution of the new scale. For example:
* $w1 = 4.190466417866504 > 0 $, so $w1_{int} = round(4.190466417866504 \cdot 2^{12}) = 17164 (binary: 0b 0100001100001100)$, re-quantizing: $17164 / 2^12 = 4.190429688$, error = $0.00003672986$. 
* $w2 = -3.3706570861002216 < 0 $, so $w2_{int} = 2^{16} - round(3.3706570861002216 \cdot 2^{12}) = 51730 (binary: 0b 1100101000010010)$, re-quantizing: $-(2^{16} - 51730) / 2^{12} = -3.370605469$, error = $0.0000516171$. 

<img width="5575" height="1647" alt="RISC-V CPU (4)" src="https://github.com/user-attachments/assets/bf70a7ac-e1bb-4f93-a3b6-c75ee851ffe5" />

The MAC unit computes the products of the 16-bit input activation and the corresponding 16-bit weight and accumulates them into a 32-bit register. When the last input has been processed through mac, the bias is added, and the result is passed to the activation function.

**Sigmoid Activation**
Many NNs use nonlinear functions such as sigmoid or hyperbolic tangent as activation functions. However, building the digital circuits that generate these functions is very challenging and resourse intensive. Instead, we generally pre-calculate their values (since we will be aware of range of the input) ans store them in ROM as a lookup table using FPGA's distributed RAM (asynchronous reading). The sum, which is the result of multiply-accumulate operation plus bias, is directly fed into the sigmoid lookup table.  However, because the sum is 32-bit value (multiplication of 2 16-bit values - input and weight - results in double-sized bits value), feeding all the bits would require a formidable memory depth ($2^{32}$). That is why we take only some most significant bits of the sum to define the depth of the sigmoid memory. 

For this, we pass the sum with a new quantization format of Qm.n, where m is calculated as (num of weight integer bits + num of input integer bits), and n is (sigmoid memory depth - m). For example, if sigmoid size is 10 and we keep the number of weight and input integer bits as 4 and 1, respectively, the Q-format of the passed value will be Q5.5. This number should represent the *address* at the sigmoid memory which holds the precomputed sigmoid value of the real input. Because the sum is a signed number, meaning it can be either positive or negative, and the address can be only positive, we need to convert the two's complement to binary offset by flipping the MSB. So, a new axis with remapped monotonically ascending addresses is used to access the corresponding sigmoid values. For example, if the sum is -1.473 (real value), then its integer value in Q5.5 is -47 (or 977), or in binary 0b 1111010001. To get the address, we flip the MSB and get 0b 0111010001, which corresponds to address 465. The value of the sigmoid at this address is 0b 0.001110100110100, or 0.228.

<img width="5540" height="3109" alt="RISC-V CPU (5)" src="https://github.com/user-attachments/assets/7ae6445c-124a-4327-866f-6210dbf2f809" />

The sigmoid lookup table was generated using the following Python script:

```python
def DtoB(num,dataWidth,fracBits): #funtion for converting into two's complement format
    if num >= 0:
        num = num * (2**fracBits)
        num = int(num)
        e = bin(num)[2:]
    else:
        num = -num
        num = num * (2**fracBits)#number of fractional bits
        num = int(num)
        if num == 0:
            d = 0
        else:
            d = 2**dataWidth - num
        e = bin(d)[2:]
    return e

def genSigContent(dataWidth,sigmoidSize,weightIntSize,inputIntSize):
    f = open("sigContent.mif","w")
    fractBits = sigmoidSize-(weightIntSize+inputIntSize) 
    if fractBits < 0: # Sigmoid size is smaller the integer part of the MAC operation
        fractBits = 0
    x = -2**(weightIntSize+inputIntSize-1) # Smallest input going to the Sigmoid LUT from the neuron
    for i in range(0,2**sigmoidSize):
        y = sigmoid(x)
        z = DtoB(y,dataWidth,dataWidth-inputIntSize)
        f.write(z+'\n')
        x=x+(2**-fractBits)
    f.close()
    
def sigmoid(x):
    try:
        return 1 / (1+math.exp(-x)) #for x less than -1023 will give value error
    except:
        return 0
```

## Instruction and Data Memories 
The RISC-V CPU coordinates the accelerator by sending custom instructions via RoCC interface. 



## Simulation 

In simulation, I imitate images transmission via UART. Specifically, 3 images, representing 7,8, and 9 digits, were uploaded as ROM and sent byte-by-byte to the private memory of the NN accelerator for furhter inference. The CPU 

```verilog
`timescale 1ns / 1ps

module tb_riscv_rx;

parameter CLK_PERIOD = 10; // 100MHz 
parameter CLKS_PER_BIT = 100; // 1_000_000 baud at 100MHz (for simulation, in real - 115200 baud)
parameter BIT_PERIOD = CLK_PERIOD * CLKS_PER_BIT; // ns per bit 

reg [7:0] im1 [783:0];
reg [7:0] im2 [783:0];
reg [7:0] im3 [783:0];
integer k;

reg clk = 0;
reg reset = 1;
reg rx = 1; // idle high 
wire [3:0] num_correct;

riscv_core #(.IMEM_INIT_FILE("mnist.mem")) cpu (.clk(clk), .reset(reset), .rx(rx), .result(num_correct));

always #(CLK_PERIOD/2) clk = ~clk;

// ---- Task: send one pixel over serial line ----
task send_pixel;
    input [7:0] byte_in;
    integer i;
    begin 
        rx = 1'b0;
        #(BIT_PERIOD);
        for (i=0; i<8; i=i+1) begin 
            rx = byte_in[i];
            #(BIT_PERIOD);
        end
        rx = 1'b1;
        #(BIT_PERIOD);
    end
endtask

// ---- Stimulus ----
initial begin 
    $dumpfile("tb_riscv_rx.vcd");
    $dumpvars(0, tb_riscv_rx);
    
    // test images (3 for now)
    $readmemb("im1.txt", im1);
    $readmemb("im2.txt", im2);
    $readmemb("im3.txt", im3);
    
    // reset 
    @(posedge clk);
    reset = 1;
    repeat(10) @(posedge clk);
    reset = 0;
    #(BIT_PERIOD); // idle gap 
    
    for (k=0; k<784; k=k+1) send_pixel(im1[k]);
    @(posedge cpu.rocc_net.tx_done);
    for (k=0; k<784; k=k+1) send_pixel(im2[k]);
    @(posedge cpu.rocc_net.tx_done);
    for (k=0; k<784; k=k+1) send_pixel(im3[k]);
    @(posedge cpu.rocc_net.tx_done);
    repeat(100) @(posedge clk);

     $finish;    
end

endmodule
```

The result:

`Detected number:          7.`

`Detected number:          8.`

`Detected number:          9.`

<img width="1047" height="641" alt="1fc18e6a-384b-470c-89bb-f070bbfbd2df" src="https://github.com/user-attachments/assets/91fe507c-80c6-4fe3-802a-141d5b4b18ac" />


## Hardware Implementation

## Performance Evaluation

### Latency 

### Throughput 

### Resource Utilization

### Accuracy 

## Acknowledgements
I would like to mention [Vipin Kizheppatt's tutrorials](https://github.com/vipinkmenon/neuralNetwork) and the [courses by EcrioniX](https://ecrionix.org/) that I used to develop this project.

