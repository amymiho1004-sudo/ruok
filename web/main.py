import os
import uvicorn

if __name__ == "__main__":
    host = os.getenv("RUOK_HOST", "127.0.0.1")
    port = int(os.getenv("RUOK_PORT", "8787"))
    uvicorn.run("app.main:app", host=host, port=port, reload=False)
