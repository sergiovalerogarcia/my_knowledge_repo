FROM debian:latest

# docker build -t my_knowledge_repo .
# docker run -d -p 7000:7000 --name my_knowledge_repo my_knowledge_repo bash -c "./run.sh"
# knowledge_repo --repo . deploy --config configfileserver.py --engine flask

# get base
RUN apt-get update && apt-get upgrade -y

# get essentials
RUN apt-get -y install git python3 python3-pip

# get Knowledge
RUN pip3 install --upgrade "knowledge-repo[all]"

# get the knowledge_repo
WORKDIR /home/


ADD https://api.github.com/repos/sergiovalerogarcia/my_knowledge_repo/git/refs/heads/master version.json
RUN git clone -b master https://github.com/sergiovalerogarcia/my_knowledge_repo.git 
WORKDIR /home/my_knowledge_repo/
RUN chmod +x run.sh

