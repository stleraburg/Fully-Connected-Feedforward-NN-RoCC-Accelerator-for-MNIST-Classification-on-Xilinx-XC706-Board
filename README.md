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

## Instruction and Data Memories 
The RISC-V CPU coordinates the accelerator by sending custom instructions via RoCC interface. To test the correctness of the NN accelerator working, the following instructions have been loaded to the CPU's instruction memory. Specifically, the CPU constantly sends READ_RESULT custom instructions and waits for the accelerator to load the test image and produce the inference result. When the result is ready, the CPU consumes it and stores it in the datamemory at a specific memory address. This address ($0x8000_0000$) is decoded as a memory-mapped output register. The data memory module checks if the store instructions operates on this address by checking the MSB (it should be "1"), and if so, it drives the lower four bits of the written value onto the GPIO LEDs, displaying the classified digit on the boar:

```verilog
else if (mem_write) begin 
     mem[address[9:2]] <= write_data;
     if (address[31] == 1'b1) begin 
         led_result <= write_data[3-:4]; // just a fancy way to write [3:0]
     end
end
```

The assembly (program.S) test program: 
```assembly
li   x19, 0x80000000      # address that drives the LEDs (bit 31 set)
loop:
    custom0 x22, x0, x0, 5    # READ_RESULT → x22
    sw   x22, 0(x19)           # store result TO the LED address
    j    loop

```

and the corresponding binary code in $readmemb format:
```
10000000000000000000100110110111
00000010000000000011101100001011
00000001011010011010000000100011
11111111100111111111000001101111
```

## Hardware Implementation
To send the images from the host PC to the FPGA via UART, I wrote the following Python script:

```python
import serial
import time
import sys
import os
import glob
import tkinter as tk
from functools import partial
from PIL import Image, ImageTk
import numpy as np
import random
import math
from tkinter import messagebox
import time

#-------Configuration----------------
PORT = "COM3"
BAUD = 115200
IMAGE_SIZE = 784
NUM_IMAGES = 25
RESULT_TIMEOUT = 10
THUMB = 100
FILE_PATTERN = "*.txt"

def load_pixels(path):
    pixels = []
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if (len(pixels) >= IMAGE_SIZE):
                break 
            val_16 = int(line, 2)
            pixels.append((val_16 >> 7) & 0xFF)
        if (len(pixels) != IMAGE_SIZE):
            raise ValueError(f"{path}: got {len(pixels)} pixels, expected {IMAGE_SIZE}")
   return pixels

def make_photo(pixels, size=THUMB):
    arr = np.array(pixels, dtype=np.uint8).reshape(28,28)
    pil =  Image.fromarray(arr, mode='L').resize((size,size), Image.NEAREST)
    return ImageTk.PhotoImage(pil)

def send_image(ser, pixels, index):
    if ser is None:
        return None
    ser.reset_input_buffer()
    ser.write(bytes(pixels))
    ser.flush()
    ser.timeout = RESULT_TIMEOUT
    result = ser.read(1)
    
    digit  = result[0]
    
    print(f"image{index}: digit={digit}")
    return digit

class DigitGUI:
    def __init__(self, root, files, ser) :
        self.root = root
        self.ser = ser
        self.photos = []
        self.pixel_sets = []
        self.result_labels = []

        root.title("MNIST over UART - click an image to classify")

        n = len(files)
        cols = math.ceil(math.sqrt(n)) # 25 -> 3x3
        rows = math.ceil(n / cols)

        for r in range(rows):
            root.rowconfigure(r*2, weight=1)
            root.rowconfigure(r*2+1, weight = 0)
        for c in range(cols):
            root.rowconfigure(c, weight=1)
        for i, path in enumerate(files):
            r,c = divmod(i, cols)
            pixels = load_pixels(path)
            photo = make_photo(pixels)
            self.pixel_sets.append(pixels)
            self.photos.append(photo)
            btn = tk.Button(root, image=photo, command=partial(self.on_click, i), borderwidth=2, relief="groove")
            btn.grid(row=r*2, column=c, padx=5, pady=(5,0), sticky="nsew")
            
            lbl = tk.Label(root, text="", font=("Arial", 9))
            lbl.grid(row=r*2+1, column=c, padx=5, pady=(0,5))
            self.result_labels.append(lbl)

    def on_click(self, index):
            pixels = self.pixel_sets[index] # the bytes behind this button
            if self.ser is None:
                messagebox.showwarning("No serial port", "Serial port not open - cannot send.")
                return 
            self.result_labels[index].config(text="sending...", fg="black")
            self.root.update_idletasks() #refresh before blocking
            digit = send_image(self.ser, pixels, index)
            if digit is None:
                self.result_labels[index].config(text="TIMEOUT", fg="red")
            else:
                self.result_labels[index].config(text=f"Predicted: {digit}", fg="green")


image_dir = "/testData"
img_files = sorted(glob.glob(os.path.join(image_dir, FILE_PATTERN)))
if not img_files:
    print(f"No files matching {FILE_PATTERN} in {image_dir}")
    sys.exit(1)
k = min(NUM_IMAGES, len(img_files))
files = random.sample(img_files, k)
print(f"Showing {k} random images from {image_dir}")

try:
    ser = serial.Serial(PORT, BAUD, timeout=RESULT_TIMEOUT)
    print(f"Opened {PORT} at {BAUD} baud")
except Exception as e:
    print(f"WARNING: could not open {PORT}: e")
    ser = None

root = tk.Tk()
gui = DigitGUI(root, files, ser)
try:
    root.mainloop()
finally:
    if ser is not None:
        ser.close()
        print("Port closed.")

```

This creates a custom GUI, displaying a 5x5 matrix of random images from test dataset using the *tkinter package* . By clicking an image in the grid, the PC transmits 784 pixel values (1 byte each) serially over a UART-USB converter to the ZC706 board at 115200 baud. In return, the FPGA sends the inferred result back, together with displaying it on the GPIO LEDs. 

<img width="291" height="355" alt="image" src="https://github.com/user-attachments/assets/9db91751-097a-4a9f-a6bd-09bcd5600913" />

As for the hardware, I used differential system clock of 200MHz as a main clock source and fed it to the clocking wizard IP to halve the frequency and, thus, meet the timing requirements. In the constraints file, the four least significant bits of the *result* signal are mapped to the on-board LED pins, and the UART rx and tx signals are routed to the PMOD1 header (J58). To establish the physical connection between the host PC and FPGA board, I used UART-USB converter and connected the common ground and well as the crossed tx and rx pins. 

The LEDs display the digit "9" in binary "1001".

<img width="192" height="256" alt="image" src="https://github.com/user-attachments/assets/7297687f-3f86-4fe7-9a2d-ab05caecaa35" />

## Performance Evaluation

### Latency 

### Throughput 

### Resource Utilization

### Accuracy 

## Acknowledgements
I would like to mention [Vipin Kizheppatt's tutrorials](https://github.com/vipinkmenon/neuralNetwork) and the [courses by EcrioniX](https://ecrionix.org/) that I used to develop this project.

