FROM python:3.11-slim

RUN pip install rasterio && \
    python -c "import rasterio; print(rasterio.__version__)"