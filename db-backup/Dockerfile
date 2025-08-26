FROM alpine:3.19

RUN apk add --no-cache postgresql-client bash coreutils

COPY entrypoint.sh /backup/entrypoint.sh
COPY backup.sh     /backup/backup.sh
RUN chmod +x /backup/*.sh

ENTRYPOINT ["/backup/entrypoint.sh"]
