FROM public.ecr.aws/sam/build-nodejs18.x:1.76.0-20230303022654

RUN npm install -g @bitwarden/cli@2023.1.0

WORKDIR /app

COPY start.sh .

CMD [ "./start.sh" ]
