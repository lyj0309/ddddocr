FROM python:3.10-slim AS runtime

# 创建非 root 用户
ARG APP_DIR
RUN useradd -m -u 10001 appuser
WORKDIR ${APP_DIR}

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on

# 仅安装运行期需要的系统依赖（按需增减）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 libgl1 \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

# 生成 wheels（使用 BuildKit 的 cache mount 加速可选）
# 需要 Docker BuildKit: DOCKER_BUILDKIT=1
RUN  pip install -r requirements.txt  
# 从 builder 拷贝打好的 wheels 并安装

# 复制项目源码
COPY . ${APP_DIR}

# 切换非 root
USER appuser

# 如为 Web 服务，开放端口（可按需修改/删除）
EXPOSE 8000

# ====== 启动命令（按你的项目选择其一）======
# 1) 直接运行脚本（例如 app.py）
# CMD ["python", "app.py"]

# 2) 运行模块
# CMD ["python", "-m", "your_package.entrypoint"]

# 3) 使用 gunicorn 启动 WSGI/ASGI 应用（Flask/Django/FastAPI）
# 例：Flask app: "app:app"；Django: "myproj.wsgi:application"；FastAPI: "main:app"
# CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000", "main:app"]

# 默认给一个保底
CMD ["python", "server.py"]
