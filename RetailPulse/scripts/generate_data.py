#!/usr/bin/env python3
"""Generate realistic retail sample data for RetailPulse BigQuery project."""

import csv
import random
from datetime import datetime, timedelta
from pathlib import Path

random.seed(42)

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "datasets"

FIRST_NAMES = [
    "James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda",
    "David", "Elizabeth", "William", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
    "Thomas", "Sarah", "Christopher", "Karen", "Daniel", "Lisa", "Matthew", "Nancy",
    "Anthony", "Betty", "Mark", "Margaret", "Donald", "Sandra", "Steven", "Ashley",
    "Paul", "Kimberly", "Andrew", "Emily", "Joshua", "Donna", "Kenneth", "Michelle",
    "Kevin", "Dorothy", "Brian", "Carol", "George", "Amanda", "Timothy", "Melissa",
    "Ronald", "Deborah", "Priya", "Raj", "Ananya", "Wei", "Mei", "Carlos", "Maria",
    "Ahmed", "Fatima", "Olivia", "Liam", "Emma", "Noah", "Sophia", "Ethan", "Ava",
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
    "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker",
    "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
    "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
    "Carter", "Roberts", "Patel", "Sharma", "Chen", "Kim", "Singh", "Kumar", "Ali",
]

CITIES_STATES = [
    ("New York", "NY"), ("Los Angeles", "CA"), ("Chicago", "IL"), ("Houston", "TX"),
    ("Phoenix", "AZ"), ("Philadelphia", "PA"), ("San Antonio", "TX"), ("San Diego", "CA"),
    ("Dallas", "TX"), ("San Jose", "CA"), ("Austin", "TX"), ("Jacksonville", "FL"),
    ("Fort Worth", "TX"), ("Columbus", "OH"), ("Charlotte", "NC"), ("San Francisco", "CA"),
    ("Indianapolis", "IN"), ("Seattle", "WA"), ("Denver", "CO"), ("Boston", "MA"),
    ("Nashville", "TN"), ("Detroit", "MI"), ("Portland", "OR"), ("Las Vegas", "NV"),
    ("Miami", "FL"), ("Atlanta", "GA"), ("Minneapolis", "MN"), ("Tampa", "FL"),
    ("Orlando", "FL"), ("Raleigh", "NC"), ("Salt Lake City", "UT"), ("Kansas City", "MO"),
]

CATEGORIES = {
    "Electronics": ["Smartphones", "Laptops", "Tablets", "Accessories", "Audio"],
    "Clothing": ["Men", "Women", "Kids", "Footwear", "Accessories"],
    "Home & Kitchen": ["Furniture", "Appliances", "Decor", "Bedding", "Storage"],
    "Sports": ["Fitness", "Outdoor", "Team Sports", "Cycling", "Yoga"],
    "Beauty": ["Skincare", "Makeup", "Haircare", "Fragrance", "Tools"],
    "Books": ["Fiction", "Non-Fiction", "Children", "Textbooks", "Comics"],
    "Grocery": ["Snacks", "Beverages", "Pantry", "Frozen", "Organic"],
    "Toys": ["Action Figures", "Board Games", "Educational", "Outdoor Toys", "Puzzles"],
}

BRANDS = [
    "TechNova", "StyleHub", "HomeEssence", "ActiveLife", "GlowBeauty",
    "ReadWell", "FreshMart", "PlayTime", "UrbanEdge", "PrimeSelect",
    "EcoChoice", "ValueMax", "LuxCraft", "SwiftGear", "PureNature",
]

GENDERS = ["Male", "Female", "Other", "Unknown", ""]
ORDER_STATUSES = ["Completed", "Cancelled", "Returned", "Pending"]
PAYMENT_METHODS = ["Credit Card", "Debit Card", "PayPal", "Apple Pay", "Google Pay", "Gift Card"]
PAYMENT_STATUSES = ["Success", "Failed", "Pending", "Refunded"]


def random_date(start: datetime, end: datetime) -> datetime:
    delta = end - start
    return start + timedelta(days=random.randint(0, delta.days))


def generate_customers(n: int = 500) -> list:
    customers = []
    for i in range(1, n + 1):
        fn = random.choice(FIRST_NAMES)
        ln = random.choice(LAST_NAMES)
        city, state = random.choice(CITIES_STATES)
        email = f"{fn.lower()}.{ln.lower()}{i}@email.com"
        phone = f"+1-{random.randint(200,999)}-{random.randint(200,999)}-{random.randint(1000,9999)}"
        signup = random_date(datetime(2019, 1, 1), datetime(2025, 6, 30))
        customers.append({
            "customer_id": f"CUST{i:05d}",
            "first_name": fn,
            "last_name": ln,
            "gender": random.choice(GENDERS),
            "email": email if random.random() > 0.02 else "",
            "phone": phone if random.random() > 0.05 else "",
            "city": city,
            "state": state if random.random() > 0.03 else state.lower(),
            "country": "USA" if random.random() > 0.01 else "",
            "signup_date": signup.strftime("%Y-%m-%d"),
        })
    customers[10]["email"] = "invalid-email"
    customers[25]["signup_date"] = "2025-13-45"
    customers[50]["state"] = "California"
    return customers


def generate_products(n: int = 200) -> list:
    products = []
    pid = 1
    for cat, subcats in CATEGORIES.items():
        for sub in subcats:
            for _ in range(max(1, n // (len(CATEGORIES) * 5))):
                if pid > n:
                    break
                cost = round(random.uniform(5, 500), 2)
                price = round(cost * random.uniform(1.15, 2.5), 2)
                products.append({
                    "product_id": f"PROD{pid:05d}",
                    "product_name": f"{random.choice(BRANDS)} {sub} {pid}",
                    "category": cat if random.random() > 0.05 else cat.lower(),
                    "subcategory": sub,
                    "brand": random.choice(BRANDS),
                    "price": price if random.random() > 0.02 else -price,
                    "cost": cost,
                    "launch_date": random_date(datetime(2018, 1, 1), datetime(2025, 6, 1)).strftime("%Y-%m-%d"),
                })
                pid += 1
            if pid > n:
                break
        if pid > n:
            break
    while len(products) < n:
        cat = random.choice(list(CATEGORIES.keys()))
        sub = random.choice(CATEGORIES[cat])
        cost = round(random.uniform(5, 500), 2)
        products.append({
            "product_id": f"PROD{len(products)+1:05d}",
            "product_name": f"{random.choice(BRANDS)} {sub} {len(products)+1}",
            "category": cat,
            "subcategory": sub,
            "brand": random.choice(BRANDS),
            "price": round(cost * 1.5, 2),
            "cost": cost,
            "launch_date": random_date(datetime(2018, 1, 1), datetime(2025, 6, 1)).strftime("%Y-%m-%d"),
        })
    return products[:n]


def generate_orders(n: int = 3000, customers: list = None) -> list:
    customer_ids = [c["customer_id"] for c in customers]
    orders = []
    weights = [0.72, 0.10, 0.08, 0.10]
    for i in range(1, n + 1):
        city, state = random.choice(CITIES_STATES)
        status = random.choices(ORDER_STATUSES, weights=weights)[0]
        order_date = random_date(datetime(2023, 1, 1), datetime(2025, 6, 30))
        discount = round(random.uniform(0, 50), 2) if random.random() > 0.6 else 0
        subtotal = round(random.uniform(20, 2000), 2)
        tax = round(subtotal * 0.08, 2)
        total = round(subtotal - discount + tax, 2)
        if status == "Cancelled" and random.random() > 0.5:
            total = round(random.uniform(-100, 0), 2)
        orders.append({
            "order_id": f"ORD{i:06d}",
            "customer_id": random.choice(customer_ids) if random.random() > 0.02 else "CUST99999",
            "order_date": order_date.strftime("%Y-%m-%d"),
            "status": status,
            "shipping_city": city,
            "shipping_state": state,
            "discount": discount,
            "tax": tax,
            "total_amount": total,
        })
    orders.append({**orders[100], "order_id": "ORD000100"})
    return orders


def generate_order_items(orders: list, products: list, target: int = 7000) -> list:
    product_ids = [p["product_id"] for p in products]
    price_map = {p["product_id"]: p["price"] for p in products}
    items = []
    item_id = 1
    for order in orders:
        num_items = random.choices([1, 2, 3, 4, 5], weights=[30, 35, 20, 10, 5])[0]
        for _ in range(num_items):
            if item_id > target:
                break
            pid = random.choice(product_ids) if random.random() > 0.01 else "PROD99999"
            unit_price = abs(price_map.get(pid, round(random.uniform(10, 500), 2)))
            items.append({
                "order_item_id": f"OI{item_id:07d}",
                "order_id": order["order_id"],
                "product_id": pid,
                "quantity": random.randint(1, 5),
                "unit_price": round(unit_price, 2),
            })
            item_id += 1
        if item_id > target:
            break
    while len(items) < target and orders:
        order = random.choice(orders)
        pid = random.choice(product_ids)
        items.append({
            "order_item_id": f"OI{len(items)+1:07d}",
            "order_id": order["order_id"],
            "product_id": pid,
            "quantity": random.randint(1, 3),
            "unit_price": round(abs(price_map.get(pid, random.uniform(10, 500))), 2),
        })
    if items:
        items.append({**items[200], "order_item_id": items[200]["order_item_id"]})
    return items[:target + 1]


def generate_payments(orders: list) -> list:
    payments = []
    for i, order in enumerate(orders, 1):
        if order["status"] == "Cancelled":
            pstatus = random.choice(["Failed", "Refunded", "Pending"])
        elif order["status"] == "Pending":
            pstatus = random.choice(["Pending", "Success"])
        else:
            pstatus = "Success" if random.random() > 0.05 else random.choice(["Failed", "Refunded"])
        pay_date = order["order_date"]
        if random.random() > 0.03:
            od = datetime.strptime(order["order_date"], "%Y-%m-%d")
            pay_date = (od + timedelta(days=random.randint(0, 3))).strftime("%Y-%m-%d")
        payments.append({
            "payment_id": f"PAY{i:06d}",
            "order_id": order["order_id"],
            "payment_method": random.choice(PAYMENT_METHODS),
            "payment_status": pstatus,
            "payment_date": pay_date,
        })
    payments.append({**payments[150], "payment_id": "PAY000151"})
    return payments


def write_csv(filename: str, rows: list, fieldnames: list):
    path = OUTPUT_DIR / filename
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} rows to {path}")


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    customers = generate_customers(500)
    products = generate_products(200)
    orders = generate_orders(3000, customers)
    order_items = generate_order_items(orders, products, 7000)
    payments = generate_payments(orders)
    write_csv("customers.csv", customers,
              ["customer_id", "first_name", "last_name", "gender", "email", "phone",
               "city", "state", "country", "signup_date"])
    write_csv("products.csv", products,
              ["product_id", "product_name", "category", "subcategory", "brand",
               "price", "cost", "launch_date"])
    write_csv("orders.csv", orders,
              ["order_id", "customer_id", "order_date", "status", "shipping_city",
               "shipping_state", "discount", "tax", "total_amount"])
    write_csv("order_items.csv", order_items,
              ["order_item_id", "order_id", "product_id", "quantity", "unit_price"])
    write_csv("payments.csv", payments,
              ["payment_id", "order_id", "payment_method", "payment_status", "payment_date"])


if __name__ == "__main__":
    main()
