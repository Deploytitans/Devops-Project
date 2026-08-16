FROM python:3.12-slim-bookworm AS builder

WORKDIR /usr/src/app
COPY ./src/recommendation/requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    RECOMMENDATION_PORT=1010
WORKDIR /usr/src/app
RUN apt-get update \
    && apt-get upgrade --yes --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app app
COPY --from=builder /install /usr/local
COPY --chown=app:app ./src/recommendation/ .
RUN opentelemetry-bootstrap -a install && rm -rf /root/.cache

USER 10001:10001
ENTRYPOINT ["python", "recommendation_server.py"]
