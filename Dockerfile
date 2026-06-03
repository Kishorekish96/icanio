FROM python:3.12-slim AS builder

WORKDIR  /app

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir --target=/install -r requirements.txt

 
FROM python:3.12-slim

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser


WORKDIR /app 

COPY --from=builder --chown=appuser:appgroup /install /install
COPY --chown=appuser:appgroup app.py . 

ENV PYTHONPATH=/install

ENV PYTHONDOWNWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1 

USER appuser

EXPOSE 5000
CMD ["python", "app.py"]