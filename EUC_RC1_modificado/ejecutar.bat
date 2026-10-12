@echo off
IF NOT EXIST .\ambiente\Scripts\activate (
    python -m venv ambiente
)
call .\ambiente\Scripts\activate
pip install -r requirements.txt
python .\EUC\main_rc1.py
pause