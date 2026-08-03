import torch # pytorch main library
import torchvision 
import torchvision.transforms as transforms
import torch.optim as optim
import torch.nn as nn
import torch.functional as F
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pickle
import gzip
import subprocess, threading, time
import json


path = 'cifar_net.pth'

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
# device = torch.device('cpu')
print(f"Using: {device}")

def load_data():
    # returns tuple containing the training data, test data, and validation data
    f = gzip.open('mnist.pkl.gz', 'rb')
    training_data, validation_data, test_data = pickle.load(f, encoding='latin1')
    f.close()
    return (training_data, validation_data, test_data)


def make_loader(split, batch_size, shuffle):
    x = torch.tensor(np.array(split[0]), dtype=torch.float32) 
    y = torch.tensor(np.array(split[1]), dtype=torch.long)
    return torch.utils.data.DataLoader(torch.utils.data.TensorDataset(x,y), batch_size=batch_size, shuffle=shuffle)

tr, va, te = load_data()
train_loader = make_loader(tr, batch_size=10, shuffle=True)
test_loader = make_loader(te, batch_size=1000, shuffle=False)
validation_loader = make_loader(va, batch_size=1000, shuffle=False)

class Net(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(784, 30)
        self.fc2 = nn.Linear(30, 30)
        self.fc3 = nn.Linear(30, 10)
        self.fc4 = nn.Linear(10, 10)

    def forward(self, x):
        x = torch.sigmoid(self.fc1(x))
        x = torch.sigmoid(self.fc2(x))
        x = torch.sigmoid(self.fc3(x))
        x = self.fc4(x)
        return x 

model = Net().to(device)


criterion = nn.CrossEntropyLoss()
optimizer = optim.SGD(model.parameters(), lr=0.05)

EPOCHS = 30
best_loss = 1e+20
for epoch in range(EPOCHS):
    # training loop
    train_loss = 0.0
    model.train()
    for i, data in enumerate(train_loader,0):
        inputs, labels = data[0].to(device), data[1].to(device)
        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        train_loss += loss.item()
    print(f'{epoch + 1},  train loss: {train_loss / i:.3f},', end = ' ')

    model.eval()
    val_loss = 0
    with torch.no_grad():
        for i, data in enumerate(validation_loader,0):
            inputs, labels = data[0].to(device), data[1].to(device)
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            val_loss += loss.item()
        print(f'val loss: {val_loss / i:.3f}')

        if val_loss < best_loss:
            print("Saving model")
            torch.save(model.state_dict(), path)

print('Finished Training')

model.load_state_dict(torch.load(path))

correct = 0
total = 0
model.eval()
with torch.no_grad():
    for data in test_loader:
        images, labels = data[0].to(device), data[1].to(device)
        outputs = model(images) # calculate outputs by running images through the network
        _, predicted = torch.max(outputs.data, 1) # the class with the highest energy is what we choose as prediction
        total += labels.size(0)
        correct += (predicted==labels).sum().item()

print(f"Accuracy of the network on the 10000 test images: {100 * correct / total} %")


# -------------- Performance Evaluation (GPU edition) ----------------
def measure_latency():
    starter, ender = torch.cuda.Event(enable_timing=True), torch.cuda.Event(enable_timing=True)
    x = torch.randn(1, 784).to(device)

    timings = np.zeros((1000,1))

    with torch.no_grad():
        # warmup
        for _ in range(50): _ = model(x)
        torch.cuda.synchronize()
        for n in range(1000):
            starter.record()
            _ = model(x)
            ender.record()
            torch.cuda.synchronize()
            curr_time = starter.elapsed_time(ender)
            timings[n] = curr_time * 1000.0 # us
    
    mean_syn = np.mean(timings)
    std_syn = np.std(timings)
    print(f"Latency: {mean_syn:.2f} us, std={std_syn:.2f} us, median={np.median(timings):.1f} us ")
    return mean_syn


def measure_throughput(batch_size):
    starter, ender = torch.cuda.Event(enable_timing=True), torch.cuda.Event(enable_timing=True)
    x = torch.randn(batch_size, 784).to(device)
    with torch.no_grad():
        # warmup
        for _ in range(50): _ = model(x)
        torch.cuda.synchronize()
        total_time = 0.0
        for n in range(100): 
            starter.record()
            _ = model(x)
            ender.record()
            torch.cuda.synchronize()
            curr_time = starter.elapsed_time(ender) / 1000
            total_time += curr_time
        thr = (100 * batch_size) / total_time
    return thr


def sample_power(stop_event, samples, timestamps, interval=0.05):
    while not stop_event.is_set():
        out = subprocess.check_output(['nvidia-smi', '--query-gpu=power.draw', '--format=csv,noheader,nounits'])
        samples.append(float(out.decode().strip()))
        timestamps.append(time.time())
        time.sleep(interval)

def measure_power(batch_size=65536, duration_s=10):
    x = torch.randn(batch_size, 784).to(device)
    with torch.no_grad():
        for _ in range(50): _ = model(x)
        torch.cuda.synchronize()
    
    #start power sampling in a background thread
    stop = threading.Event()
    samples, timestamps = [], []
    sampler = threading.Thread(target=sample_power, args=(stop, samples, timestamps))
    sampler.start()
    count = 0

    # inference load 
    t_end = time.time() + duration_s
    with torch.no_grad():
        while time.time() < t_end:
            _ = model(x)
            count += batch_size
        torch.cuda.synchronize()

    stop.set()
    sampler.join()

    p = np.array(samples)
    t = np.array(timestamps)
    total_energy = np.trapezoid(p, t)

    energy_per_inference = total_energy / count
    return p.mean(), energy_per_inference


print("Measuring idle power")
time.sleep(3)
idle = float(subprocess.check_output(['nvidia-smi', '--query-gpu=power.draw', '--format=csv,noheader,nounits']).decode().strip())
print(f"Idle power: {idle:.1f} W")

# LATENCY
latency = measure_latency()

# THROUGHPUT
# for bs in [1, 32, 128, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576]:
for bs in [1, 32, 128, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536]:
    try:
        print(f"batch={bs}: {measure_throughput(bs):.0f} images/s")
    except RuntimeError as e:
        if "out of memory" in str(e).lower():
            print(f"OOM at batch={bs}")
            torch.cuda.empty_cache()
            break
        raise
    finally:
        torch.cuda.empty_cache()


# POWER
power_mean, energy_inf = measure_power()
print(f"Power under load: {power_mean:.1f} W ")
print(f"Dynamic (inference) power: {power_mean - idle:.1f} W")
print(f"Energy per inference: {energy_inf*1e6:.3f} uJ")

p_b1, e_batch1 = measure_power(batch_size=1)
print(f"Batch=1: power={p_b1:.1f} W, energy={e_batch1*1e3:.3f} mJ/inference")

state = model.state_dict()
layer_names = ['fc1', 'fc2', 'fc3', 'fc4']

weights = []
biases = []

for name in layer_names:
    w = state[f'{name}.weight'].cpu().numpy()
    b = state[f'{name}.bias'].cpu().numpy()
    weights.append(w.tolist())
    biases.append([[float(bias)] for bias in b])

data = {
        'sizes': [784, 30, 30, 10, 10],
        'weights': weights,
        'biases': biases, 
        'cost': 'CrossEntropyCost'
    }

# with open ('C:/Users/stleraburg/Desktop/nnFPGA_mnist/WeightsAndBiases_2.txt', 'w') as f:
#     json.dump(data, f)
# print("Saved.")