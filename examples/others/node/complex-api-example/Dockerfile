FROM node:17
LABEL maintainer="Fred Lackey <fred.lackey@gmail.com>"
LABEL version="0.0.0"
LABEL description="Complex API Example"

COPY ./ /home/node/app/

WORKDIR /home/node/app

EXPOSE 3000

RUN npm install

CMD ["node", "./src/index.js"]
