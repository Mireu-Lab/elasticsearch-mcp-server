# 1. 기반 이미지 설정
FROM python:3.10-alpine

# 2. 작업 디렉토리 설정
WORKDIR /app
COPY . .

RUN ls

# 3. 보안을 위해 비-루트 사용자 생성 및 전환
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 5. 의존성 설치 (빌드용 패키지는 설치 후 즉시 제거)
RUN apk add --no-cache --virtual .build-deps gcc musl-dev && \
    pip install --no-cache-dir -r requirements.txt && \
    apk del .build-deps


# 7. 환경 변수 설정 (런타임에 외부에서 주입)
ENV ELASTIC_USERNAME="" \
    ELASTIC_PASSWORD="" \
    ELASTIC_HOST=""

# 8. 서버 포트 노출
EXPOSE 8080

# 9. 서버 실행
CMD "uv run src/server.py elasticsearch-mcp-server --transport sse --host 0.0.0.0 --port 8000 --path /sse"