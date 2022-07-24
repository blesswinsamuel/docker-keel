# https://github.com/keel-hq/keel/blob/master/Dockerfile

# Stage: Source
FROM --platform=${BUILDPLATFORM} alpine as source

ENV VERSION=master

WORKDIR /tmp

RUN wget https://github.com/keel-hq/keel/archive/refs/heads/${VERSION}.tar.gz && \
    tar -xvf ${VERSION}.tar.gz && \
    rm ${VERSION}.tar.gz && \
    mv /tmp/keel-${VERSION} /src

WORKDIR /src

# Stage: Build UI assets
FROM --platform=${BUILDPLATFORM} node:16-alpine as ui
WORKDIR /app
COPY --from=source /src/ui /app
RUN yarn
RUN yarn run lint --no-fix
RUN yarn run build

# Stage: Build go binary
FROM golang:1.18 as gobinary
COPY --from=source /src /go/src/github.com/keel-hq/keel
WORKDIR /go/src/github.com/keel-hq/keel
RUN make install

# Stage: Build final image
FROM alpine:latest
RUN apk --no-cache add ca-certificates

VOLUME /data
ENV XDG_DATA_HOME /data

COPY --from=gobinary /go/bin/keel /bin/keel
COPY --from=ui /app/dist /www
ENTRYPOINT ["/bin/keel"]
EXPOSE 9300
