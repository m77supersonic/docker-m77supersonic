FROM python:3.13-slim
WORKDIR /work
COPY app/requirements.txt ./
RUN pip install -r requirements.txt
COPY app/app.py ./
EXPOSE 8000
CMD ["python3", "app.py"]