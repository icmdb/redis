FROM redis:5.0.5
ENV PATH=.:/redis/:$PATH
COPY . /redis/
RUN set -xue; \
        apt-get update && apt-get -y install \
            netcat \
            && \
        apt-get autoremove && apt-get clean all
CMD [ "/redis/docker-entrypoint.sh" ]
