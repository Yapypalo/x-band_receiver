# Dockerfile для GNU Radio 3.8.0.5 + libiio + gr-dslwp + gr-lilacsat
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8

# 1. Устанавливаем зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git wget pkg-config \
    python3.8 python3.8-dev python3-pip python3-numpy python3-mako python3-click python3-click-plugins \
    python3-six libvolk2-dev\
    libboost-all-dev libgmp-dev libmpfr-dev libusb-1.0-0-dev \
    libcomedi-dev libsdl1.2-dev libfftw3-dev libcppunit-dev libgsl-dev \
    libqt5gui5 python3-pyqt5 python3-pyqt5.qtsvg python3-gi python3-gi-cairo \
    libsndfile1-dev liborc-0.4-dev swig doxygen libspdlog-dev libjson-c-dev libxml2-dev \
    libzstd-dev libavahi-client-dev libavahi-common-dev bison flex \
    libaio-dev liblog4cpp5-dev \
    python2 python2-dev libpython2.7 libpython2.7-dev \
    python3-yaml gir1.2-gtk-3.0 gir1.2-pango-1.0 python3-gi-cairo \
    python3-pyqtgraph python3-matplotlib libad9361-dev libiio-dev python3-libiio \
    libqt5gui5 libqt5core5a libqt5widgets5 \
    qttools5-dev qttools5-dev-tools \
    libqt5svg5-dev \
    python3-pyqt5 python3-pyqt5.qtsvg libqwt-qt5-6 libqwt-qt5-dev\
 && rm -rf /var/lib/apt/lists/*

# Устанавливаем python3.8 как default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

# 3. Сборка GNU Radio 3.8.0.5
RUN git clone --branch maint-3.8 --single-branch --depth 1 \
    --recurse-submodules  https://github.com/gnuradio/gnuradio.git /tmp/gnuradio \
 && cd /tmp/gnuradio \
 && git fetch --tags \
 && git checkout v3.8.5.0 \
 && git submodule update --init --recursive \
 && mkdir build && cd build \
 && cmake .. \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DENABLE_PYTHON=ON \
	-DENABLE_GR_SWIG=ON \
	-DENABLE_SWIG=ON \
	-DENABLE_GR_QTGUI=ON \
	-DENABLE_GRC=ON \
	-DENABLE_GRC_DOCS=OFF \
 && make -j$(nproc) && make install \
 && ldconfig \
 && rm -rf /tmp/gnuradio

# Устанавливаем gr-iio (IIO blocks)
RUN git clone https://github.com/analogdevicesinc/gr-iio.git /tmp/gr-iio \
 && cd /tmp/gr-iio \
    # конвертим питон-скрипты в Python3
 && python3 -m lib2to3 -w python \
 && mkdir build && cd build \
    #  задаём CXXFLAGS и SWIG_FLAGS в окружении, чтобы добавить include‑пути
 && CXXFLAGS="-I/usr/include/gnuradio -I/usr/include/gnuradio/swig" \
    SWIG_FLAGS="-I/usr/include/gnuradio/swig" \
    cmake .. \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DENABLE_PYTHON=ON \
      -DPYTHON_EXECUTABLE=/usr/bin/python3 \
      -DPYTHON_LIBRARIES=/usr/lib/x86_64-linux-gnu/libpython3.8.so \
      -DPYTHON_INCLUDE_DIRS=/usr/include/python3.8 \
      -DIIO_INCLUDE_DIRS=/usr/include \
      -DIIO_LIBRARIES=/usr/lib/x86_64-linux-gnu/libiio.so \
      -DGNURADIO_SWIG_DIR=/usr/include/gnuradio/swig \
      -DGNURADIO_RUNTIME_INCLUDE_DIRS=/usr/include/gnuradio \
 && make -j$(nproc) && make install && ldconfig \
 && rm -rf /tmp/gr-iio

# 5. gr-dslwp с правками для SWIG
RUN git clone --branch maint-3.8 https://github.com/bg2bhc/gr-dslwp.git /tmp/gr-dslwp \
 && cd /tmp/gr-dslwp \
 && mkdir build && cd build \
 && cmake .. \
       -DCMAKE_PREFIX_PATH=/usr \
       -DENABLE_PYTHON=ON \
       -DPYTHON_EXECUTABLE=/usr/bin/python3 \
       -DPYTHON_LIBRARIES=/usr/lib/x86_64-linux-gnu/libpython3.8.so \
       -DPYTHON_INCLUDE_DIRS=/usr/include/python3.8 \
       -DSWIG_EXECUTABLE=/usr/bin/swig4.0 \
       -DGNURADIO_SWIG_DIR=/usr/include/gnuradio/swig \
 && make -j$(nproc) && make install \
 && ldconfig \
 && rm -rf /tmp/gr-dslwp

# 6. gr-gpredict-doppler (зависимость для gr-lilacsat)
RUN git clone https://github.com/wnagele/gr-gpredict-doppler.git /tmp/gr-gpredict-doppler \
 && cd /tmp/gr-gpredict-doppler \
 && sed -i 's|add_subdirectory(python)|#add_subdirectory(python)|' CMakeLists.txt \ 
 && sed -i 's|^find_package(Gnuradio.*REQUIRED)|find_package(Gnuradio REQUIRED)|' CMakeLists.txt \
 && mkdir build && cd build \
 && cmake .. -DCMAKE_PREFIX_PATH=/usr -DENABLE_PYTHON=OFF \
 && make -j$(nproc) && make install \
 && ldconfig \
 && rm -rf /tmp/gr-gpredict-doppler

# 7. gr-lilacsat
RUN git clone https://github.com/bg2bhc/gr-lilacsat.git /tmp/gr-lilacsat \
 && sed -i 's|^find_package(Gnuradio.*REQUIRED)|find_package(Gnuradio REQUIRED)|' /tmp/gr-lilacsat/CMakeLists.txt \
 && mkdir /tmp/gr-lilacsat/build && cd /tmp/gr-lilacsat/build \
 && cmake .. \
      -DCMAKE_PREFIX_PATH=/usr \
      -DENABLE_PYTHON=ON \
      -DPYTHON_EXECUTABLE=/usr/bin/python3 \
      -DPYTHON_LIBRARIES=/usr/lib/x86_64-linux-gnu/libpython3.8.so \
      -DPYTHON_INCLUDE_DIRS=/usr/include/python3.8 \
 && make -j$(nproc) && make install \
 && ldconfig && rm -rf /tmp/gr-lilacsat

# 8. Чистим кеш и готово
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["/bin/bash"]
