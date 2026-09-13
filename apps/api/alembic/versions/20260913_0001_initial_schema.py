"""Create OrderFlow orders and order events.

Revision ID: 20260913_0001
Revises:
"""
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260913_0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "orders",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("sku", sa.String(length=64), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("delivery_zone", sa.String(length=16), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("sequence", sa.Integer(), nullable=False),
        sa.Column("environment", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("quantity >= 1 AND quantity <= 100", name="ck_orders_quantity"),
        sa.CheckConstraint("sequence >= 1", name="ck_orders_sequence"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_orders_environment", "orders", ["environment"])
    op.create_index("ix_orders_status", "orders", ["status"])
    op.create_table(
        "order_events",
        sa.Column("event_id", sa.String(length=36), nullable=False),
        sa.Column("order_id", sa.String(length=36), nullable=False),
        sa.Column("schema_version", sa.String(length=8), nullable=False),
        sa.Column("event_type", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("sequence", sa.Integer(), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("correlation_id", sa.String(length=36), nullable=False),
        sa.Column("source", sa.String(length=64), nullable=False),
        sa.Column("environment", sa.String(length=32), nullable=False),
        sa.CheckConstraint("sequence >= 1", name="ck_order_events_sequence"),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("event_id"),
        sa.UniqueConstraint("order_id", "sequence", name="uq_order_events_order_sequence"),
    )
    op.create_index("ix_order_events_correlation_id", "order_events", ["correlation_id"])
    op.create_index("ix_order_events_environment", "order_events", ["environment"])
    op.create_index("ix_order_events_order_id", "order_events", ["order_id"])


def downgrade() -> None:
    op.drop_index("ix_order_events_order_id", table_name="order_events")
    op.drop_index("ix_order_events_environment", table_name="order_events")
    op.drop_index("ix_order_events_correlation_id", table_name="order_events")
    op.drop_table("order_events")
    op.drop_index("ix_orders_status", table_name="orders")
    op.drop_index("ix_orders_environment", table_name="orders")
    op.drop_table("orders")
