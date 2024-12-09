FROM python:3.10-slim

RUN apt update && \
    apt-get install -y libexpat1 build-essential

RUN pip install rasterio rio-color numpy==1.21.6 && \
    python -c "import rasterio; print(rasterio.__version__)" && \
    rio color --help