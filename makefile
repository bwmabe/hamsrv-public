docker:
	sudo docker image build -t bmabe/hamsrv .
run: docker
	sudo docker container run -it --rm -p 9999:80 bmabe/hamsrv
