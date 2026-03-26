import torch


def get_default_device() -> str:
    """Returns the best available device: 'cuda' > 'mps' > 'cpu'."""
    if torch.cuda.is_available():
        return "cuda"
    if hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
        return "mps"
    return "cpu"


def get_autocast_device_type(device) -> str:
    """Returns device type string for torch.autocast.

    MPS does not support torch.autocast('mps'), so it falls back to 'cpu'.
    Accepts a torch.device, a string, or anything with a .type attribute.
    """
    device_type = device.type if hasattr(device, 'type') else str(device)
    if device_type == 'cuda':
        return 'cuda'
    return 'cpu'
