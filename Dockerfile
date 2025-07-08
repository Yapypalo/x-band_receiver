FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PREFIX=/opt/pybombs

# 1) Системные зависимости для сборки всех модулей
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget python3-pip python3-dev python3-numpy \
    python3-mako python3-click python3-click-plugins python3-six \
    libboost-all-dev libgmp-dev libmpfr-dev libfftw3-dev libusb-1.0-0-dev \
    libsdl1.2-dev libcppunit-dev libgsl-dev swig doxygen \
    python3-gi python3-gi-cairo python3-yaml qttools5-dev qttools5-dev-tools \
    qttools5-dev qttools5-dev-tools \
    libqt5svg5-dev \
    python3-pyqt5 python3-pyqt5.qtsvg libqwt-qt5-6 libqwt-qt5-dev\
    && rm -rf /var/lib/apt/lists/*

# 2) Устанавливаем PyBOMBS
RUN pip3 install pybombs

RUN mkdir -p /root/.pybombs/recipes/local/qt5
RUN echo "install: none" > /root/.pybombs/recipes/local/qt5/qt5.lwr
RUN pybombs recipes add local /root/.pybombs/recipes/local

# 3) Инициализируем префикс
RUN pybombs auto-config
RUN pybombs recipes add-defaults
RUN pybombs prefix init ${PREFIX} -R gnuradio38

# 4) Добавляем официальные и свои «рецепты»
RUN pybombs recipes add gr-recipes \
       https://github.com/gnuradio/gr-recipes.git && \
    pybombs recipes add gr-iio \
       https://github.com/analogdevicesinc/gr-iio.git && \
    pybombs recipes add gr-dslwp \
       https://github.com/bg2bhc/gr-dslwp.git && \
    pybombs recipes add gr-lilacsat \
       https://github.com/bg2bhc/gr-lilacsat.git

# 5) Устанавливаем всё вместе одной командой
RUN pybombs install \
      gnuradio \
      libiio \
      gr-iio \
      gr-dslwp \
      gr-lilacsat

# 6) Прописываем окружение
ENV PATH="${PREFIX}/bin:${PREFIX}/sbin:${PATH}" \
    LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH}" \
    PYTHONPATH="${PREFIX}/lib/python3.8/site-packages:${PYTHONPATH}"

WORKDIR /workspace
CMD ["bash"]
