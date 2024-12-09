FROM python:3.11-slim

RUN apt update && \
    apt-get install libexpat1

RUN pip install rasterio==1.4.3 && \
    python -c "import rasterio; print(rasterio.__version__)"