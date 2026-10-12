@echo off
cd /d "%~dp0"
IF NOT EXIST .\ambiente\Scripts\activate (
    python -m venv ambiente
)
call .\ambiente\Scripts\activate
pip install -r requirements.txt
python .\src\main.py
pause
