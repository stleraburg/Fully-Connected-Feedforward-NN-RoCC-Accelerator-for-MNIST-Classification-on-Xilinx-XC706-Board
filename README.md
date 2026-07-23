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
The architecture of the proposed NN is 784-30-30-10-10-1. 

### Neuron 

### Sigmoid Activation 

### Hardmax 

## Instruction and Data Memories 

## Simulation 

## Hardware Implementation
