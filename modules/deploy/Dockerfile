FROM alpine

RUN apk update
RUN apk add git openssh-client docker jq
RUN apk add curl
COPY update-version-wrapper /
CMD /update-version-wrapper
