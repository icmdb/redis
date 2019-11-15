FROM redis:5.0.6
ENV PATH=.:/redis/:$PATH
COPY . /redis/
CMD [ "/redis/docker-entrypoint.sh" ]
