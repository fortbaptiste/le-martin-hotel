"""Knowledge base models — FAQ, restaurants, beaches, activities, etc."""

from __future__ import annotations

from pydantic import BaseModel


class FAQ(BaseModel):
    id: str
    question_fr: str
    question_en: str
    answer_fr: str
    answer_en: str
    category: str | None = None


class Room(BaseModel):
    id: str
    slug: str
    name: str
    category: str
    public_category_fr: str | None = None
    public_category_en: str | None = None
    size_m2: int
    bed_type: str = "Queen"
    bed_twinable: bool = False
    extra_bed_price: float | None = 115.00
    child_supplement: float | None = 150.00
    view_fr: str | None = None
    view_en: str | None = None
    floor: str | None = None
    terrace: str | None = None
    capacity_adults: int = 2
    capacity_children: int = 0
    description_fr: str | None = None
    description_en: str | None = None
    design_style: str | None = None
    amenities: list[str] = []
    accessibility: bool = False
    is_communicating: bool = False
    communicating_with: str | None = None
    price_low_season: float | None = None
    price_high_season: float | None = None


class Restaurant(BaseModel):
    id: str
    name: str
    area: str
    cuisine: str | None = None
    price: str = "€€"
    avg_price_eur: int | None = None
    phone: str | None = None
    website: str | None = None
    rating: float | None = None
    hours: str | None = None
    closed_day: str | None = None
    reservation_required: bool = False
    specialties: str | None = None
    vegetarian_options: bool = True
    ambiance: str | None = None
    distance_km: float | None = None
    driving_time_min: int | None = None
    best_for: list[str] = []
    description_fr: str | None = None
    description_en: str | None = None
    is_partner: bool = False


class Beach(BaseModel):
    id: str
    name: str
    side: str
    distance_km: float | None = None
    driving_time_min: int | None = None
    walking_time_min: int | None = None
    characteristics: str | None = None
    facilities: str | None = None
    crowd_level: str | None = None
    best_for: list[str] = []
    description_fr: str | None = None
    description_en: str | None = None


class Activity(BaseModel):
    id: str
    name_fr: str
    name_en: str
    category: str
    operator: str | None = None
    location: str | None = None
    distance_km: float | None = None
    price_from_eur: float | None = None
    price_to_eur: float | None = None
    duration: str | None = None
    phone: str | None = None
    website: str | None = None
    description_fr: str | None = None
    description_en: str | None = None
    best_for: list[str] = []
    booking_required: bool = False


class HotelService(BaseModel):
    id: str
    slug: str
    name_fr: str
    name_en: str
    category: str
    description_fr: str | None = None
    description_en: str | None = None
    price_eur: float | None = None
    price_note: str | None = None
    is_complimentary: bool = False


class PracticalInfo(BaseModel):
    id: str
    category: str
    name: str
    address: str | None = None
    phone: str | None = None
    distance_km: float | None = None
    driving_time_min: int | None = None
    hours: str | None = None
    notes: str | None = None


class Partner(BaseModel):
    id: str
    name: str
    service_type: str
    contact_name: str | None = None
    contact_email: str | None = None
    contact_phone: str | None = None
    website: str | None = None
    description_fr: str | None = None
    description_en: str | None = None
    pricing_info: str | None = None
    notes: str | None = None


class TransportSchedule(BaseModel):
    id: str
    route: str
    operator: str
    departure_time: str
    arrival_time: str | None = None
    day_of_week: str = "daily"
    duration_minutes: int | None = None
    price_amount: float | None = None
    price_currency: str = "EUR"
    notes: str | None = None


class EmailTemplate(BaseModel):
    id: str
    category: str
    name: str
    language: str = "fr"
    channel: str = "email"
    subject_line: str | None = None
    body: str
    variables: list[str] = []
    notes: str | None = None


class EmailExample(BaseModel):
    id: str
    category: str
    title: str
    client_message: str
    marion_response: str
    context: str | None = None
    learnings: list[str] = []
    language: str = "en"
