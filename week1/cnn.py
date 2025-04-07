import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
import matplotlib.pyplot as plt

def main():
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])

    train_dataset = datasets.MNIST(root='./data', train=True, download=True, transform=transform)
    test_dataset = datasets.MNIST(root='./data', train=False, download=True, transform=transform)

    train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True)
    test_loader = DataLoader(test_dataset, batch_size=1000, shuffle=False)

    class SimpleCNN(nn.Module):
        def __init__(self):
            super(SimpleCNN, self).__init__()
            self.conv_layer = nn.Sequential(
                nn.Conv2d(1, 16, kernel_size=3, padding=1),
                nn.ReLU(),
                nn.MaxPool2d(2),
                nn.Conv2d(16, 32, kernel_size=3, padding=1),
                nn.ReLU(),
                nn.MaxPool2d(2)
            )
            self.fc_layer = nn.Sequential(
                nn.Flatten(),
                nn.Linear(32 * 7 * 7, 128),
                nn.ReLU(),
                nn.Linear(128, 10)
            )

        def forward(self, x):
            x = self.conv_layer(x)
            x = self.fc_layer(x)
            return x

    model = SimpleCNN()
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    epochs = 5
    for epoch in range(epochs):
        model.train()
        total_loss = 0
        for batch in train_loader:
            images, labels = batch
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
        print(f"Epoch {epoch+1}/{epochs}, Loss: {total_loss:.4f}")

    model.eval()
    correct = 0
    total = 0
    with torch.no_grad():
        for images, labels in test_loader:
            outputs = model(images)
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()

    print(f"Test Accuracy: {100 * correct / total:.2f}%")

    # Sample training data
    examples = enumerate(train_loader)
    batch_idx, (example_data, example_targets) = next(examples)
    fig = plt.figure(figsize=(10, 4))
    for i in range(6):
        plt.subplot(1, 6, i + 1)
        plt.tight_layout()
        plt.imshow(example_data[i][0], cmap='gray', interpolation='none')
        plt.title(f"Label: {example_targets[i]}")
        plt.xticks([]); plt.yticks([])

    images, labels = next(iter(test_loader))
    outputs = model(images)
    _, preds = torch.max(outputs, 1)

    fig = plt.figure(figsize=(12, 6))
    for i in range(10):
        plt.subplot(2, 5, i + 1)
        plt.imshow(images[i][0], cmap='gray')
        plt.title(f"Pred: {preds[i].item()}, True: {labels[i].item()}")
        plt.axis('off')
    plt.suptitle('CNN Predictions vs Ground Truth')
    plt.tight_layout()

    def visualize_feature_maps(model, image):
        model.eval()
        with torch.no_grad():
            x = image.unsqueeze(0)
            feature_maps = model.conv_layer[0](x)
        fig, axes = plt.subplots(2, 8, figsize=(12, 4))
        for i, ax in enumerate(axes.flat):
            ax.imshow(feature_maps[0, i].detach().numpy(), cmap='viridis')
            ax.set_title(f"Filter {i}")
            ax.axis('off')
        plt.tight_layout()
        plt.suptitle("Feature Maps from First Conv Layer")

    img = test_dataset[0][0]
    visualize_feature_maps(model, img)

if __name__ == "__main__":
    main()

