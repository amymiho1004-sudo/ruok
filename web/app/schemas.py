from typing import Any, Optional
from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    name: str = Field(min_length=1)
    email: str = Field(min_length=3)
    password: str = Field(min_length=6)
    phone: Optional[str] = None


class LoginRequest(BaseModel):
    email: str
    password: str


class CreateDeviceRequest(BaseModel):
    family_name: str = "My Family"
    name: str = "Home Device"
    location: Optional[str] = "Home"


class DeviceEventRequest(BaseModel):
    event_type: str
    detected: Optional[bool] = None
    value_text: Optional[str] = None
    value_number: Optional[float] = None
    timestamp: Optional[str] = None
    meta: Optional[dict[str, Any]] = None


class SleepScheduleRequest(BaseModel):
    start_time: str = "22:00"
    end_time: str = "07:00"
    days_of_week: str = "0,1,2,3,4,5,6"
    enabled: bool = True


class PresenceModeRequest(BaseModel):
    mode_type: str
    start_at: str
    end_at: Optional[str] = None
    note: Optional[str] = None
    enabled: bool = True


class AlertRulesRequest(BaseModel):
    normal_warning_minutes: int = 180
    normal_urgent_minutes: int = 360
    sleep_warning_minutes: int = 720
    sleep_urgent_minutes: int = 840
    offline_minutes: int = 30
    enabled: bool = True
