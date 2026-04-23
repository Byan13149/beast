import time
for mod in [ 'torchvision', 'cv2', 'jaxtyping', 'beast.api.model']:
    t = time.time()
    __import__(mod)
    print(f"{mod}: {time.time()-t:.2f}s", flush=True)