import json
import mysql.connector
from mysql.connector import pooling
from contextlib import contextmanager
from threading import Lock

# 单例模式
class DbManagerSingleton:
    _instance = None
    _lock = Lock() # 线程锁，确保线程安全

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            with cls._lock:
                if not cls._instance:
                    cls._instance = super().__new__(cls)
                    # 注意：在标准的 Python 单例实现中，通常不需要手动调用 __init__，
                    # 除非你确定要覆盖 Python 的默认行为。这里保留图片中的逻辑。
                    # 如果遇到初始化两次的问题，可以考虑移除这一行。
                    # cls._instance.__init__(*args, **kwargs) 
        return cls._instance

    def __init__(self, host, port, user, password, database):
        # 防止在单例模式下重复初始化
        if hasattr(self, 'connection_pool'):
            return

        self.connection_pool = mysql.connector.pooling.MySQLConnectionPool(
            pool_name="db_pool",
            pool_size=5,
            pool_reset_session=True, # 图片中显示为 pool_reset_sessinotallow，已修正为标准参数
            host=host,      # 数据库服务器Host
            port=port,      # 数据库服务器端口
            user=user,      # 数据库用户名
            password=password, # 数据库密码
            database=database, # 数据库名
        )

    @contextmanager
    def get_cursor(self):
        with self.connection_pool.get_connection() as connection:
            cursor = None
            try:
                cursor = connection.cursor()
                yield cursor
                connection.commit()
            except Exception as e:
                connection.rollback()
                raise e
            finally:
                if cursor:
                    cursor.close()

    def execute_sql(self, sql: str) -> str:
        with self.get_cursor() as cursor:
            cursor.execute(sql)
            if cursor.description is not None:
                rows = cursor.fetchall()
                result = {
                    "columns": [desc[0] for desc in cursor.description],
                    "rows": rows,
                }
                return json.dumps(result, default=str)
            else:
                return f"row affected:{cursor.rowcount}"