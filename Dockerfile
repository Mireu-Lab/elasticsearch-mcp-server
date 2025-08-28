# 1. 기반 이미지 설정
FROM python:3.10-alpine

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 보안을 위해 비-루트 사용자 생성
# USER 전환은 소스 코드 복사 및 설치 이후에 진행합니다.
RUN addgroup -S mcpgroup &&\
    adduser -S mcpuser -G mcpgroup

# 4. 의존성 정의 파일 먼저 복사 (Docker 캐시 활용)
COPY pyproject.toml .

# 5. 의존성 설치 (빌드용 패키지는 설치 후 즉시 제거)
# 'pip install .' 명령어는 pyproject.toml을 읽어 필요한 모든 것을 설치합니다.
RUN apk add --no-cache --virtual .build-deps gcc musl-dev && \
    pip install --no-cache-dir . && \
    apk del .build-deps

# 6. 나머지 소스 코드 복사
COPY src ./src

# 7. 생성한 비-루트 사용자로 전환
USER mcpuser

# 8. 런타임에 주입될 환경 변수들을 정의합니다.
ENV ELASTIC_USERNAME="" \
    ELASTIC_PASSWORD="" \
    ELASTIC_HOST=""

# 9. 서버 포트를 외부에 노출합니다.
EXPOSE 8080

# 10. 컨테이너 실행 시 서버를 시작하는 명령입니다.
# README를 참고하여 streamable-http 전송 방식을 사용합니다.
CMD ["python", "-m", "src.server", "elasticsearch-mcp-server", "--transport", "streamable-http", "--host", "0.0.0.0", "--port", "8080"]