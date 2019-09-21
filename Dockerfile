FROM redis:5.0.5
ENV PATH=.:/redis/:$PATH
COPY . /redis/
WORKDIR /redis
CMD [ "/redis/docker-entrypoint.sh" ]
