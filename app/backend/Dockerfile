FROM python:3.9-buster
COPY . .
RUN pip install --upgrade pip && pip install -r requirements.txt
EXPOSE 8080
ENTRYPOINT ["python", "app.py"]