FROM quay.io/apibara/sink-webhook:0.6.0 as sink-webhook

WORKDIR /indexer
COPY ./indexer/script.js .

CMD ["run", "script.js", "--allow-env", "indexer.env", "--allow-env-from-env", "EVENT_TARGET_URL,APIBARA_STREAM_URL", "--allow-net", "--sink-id", "art-peace-sink-id"]