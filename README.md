# x-band_reciver

## Installing PyBOMBS Docker
---

### Build
```bash
sudo docker build -t gnuradio:latest .
```

### Run
```bash
sudo docker run -it --rm --network=host -e DISPLAY=:1 -v /tmp/.X11-unix:/tmp/.X11-unix --name grc -v "$HOME/Desktop/asrtu:/home" gnuradio:latest
```
