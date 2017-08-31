FROM alpine

RUN apk update
RUN apk add git openssh-client curl jq
COPY update-version-wrapper /
CMD /update-version-wrapper
