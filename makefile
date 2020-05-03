NAME=mi-ns3

build: Dockerfile
	docker build -t $(NAME) .

run:
	docker run -it -e DISPLAY   --net=host $(NAME):latest 