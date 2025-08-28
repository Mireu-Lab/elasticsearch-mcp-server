# Python 3.10을 기반 이미지로 사용
FROM python:3.10-slim

# 작업 디렉토리 설정
WORKDIR /app
# 저장소 복제
COPY . .

# Git 설치
RUN apt-get update &&\
    apt-get upgrade -y &&\
    rm -rf /var/lib/apt/lists/* &&\
    apt-get install -y git &&\
    apt-get clean

RUN git clone https://github.com/Mireu-Lab/elasticsearch-mcp-server.git .

# Python 의존성 설치
RUN pip install --no-cache-dir -r requirements.txt

ENV ELASTIC_USERNAME= \
    ELASTIC_PASSWORD= \
    ELASTIC_HOST=

# 서버 포트 노출
EXPOSE 8080

# 서버 실행
# streamable-http 프로토콜을 사용하여 0.0.0.0 주소와 8080 포트에서 서버를 실행
CMD ["python", "-m", "src.server", "streamable-http", "--host", "0.0.0.0", "--port", "8080"]