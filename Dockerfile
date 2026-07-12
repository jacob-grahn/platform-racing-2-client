FROM nginx:alpine

COPY export/html5/bin/ /usr/share/nginx/html/

EXPOSE 80

