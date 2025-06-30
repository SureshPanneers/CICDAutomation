
from flask import Flask, jsonify
from datetime import date
from random import randint, choice
from collections import defaultdict

app = Flask(__name__)

class QuarterlyIncomeReport:
    class SalesData:
        def __init__(self, date_sold, department_name, product_id, quantity_sold, unit_price, base_cost, volume_discount):
            self.date_sold = date_sold
            self.department_name = department_name
            self.product_id = product_id
            self.quantity_sold = quantity_sold
            self.unit_price = unit_price
            self.base_cost = base_cost
            self.volume_discount = volume_discount

    class ProdDepartments:
        department_names = ["Men's Clothing", "Women's Clothing", "Children's Clothing", "Accessories", "Footwear", "Outerwear", "Sportswear", "Undergarments"]
        department_abbreviations = ["MENS", "WOMN", "CHLD", "ACCS", "FOOT", "OUTR", "SPRT", "UNDR"]

    class ManufacturingSites:
        manufacturing_sites = ["US1", "US2", "US3", "UK1", "UK2", "UK3", "JP1", "JP2", "JP3", "CA1"]

    def generate_sales_data(self):
        sales_data = []
        for _ in range(1000):
            date_sold = date(2023, randint(1, 12), randint(1, 28))
            department_name = choice(self.ProdDepartments.department_names)
            department_index = self.ProdDepartments.department_names.index(department_name)
            department_abbreviation = self.ProdDepartments.department_abbreviations[department_index]
            product_id = f"{department_abbreviation}-{department_index+1:01}{randint(1,99):02}-{choice(['XS','S','M','L','XL'])}-{choice(['BK','BL','GR','RD','YL','OR','WT','GY'])}-{choice(self.ManufacturingSites.manufacturing_sites)}"
            quantity_sold = randint(1, 100)
            unit_price = randint(25, 299) + randint(0, 99) / 100
            base_cost = unit_price * (1 - randint(5, 20) / 100)
            volume_discount = int(quantity_sold * 0.1)
            sales_data.append(self.SalesData(date_sold, department_name, product_id, quantity_sold, unit_price, base_cost, volume_discount))
        return sales_data

    def get_quarter(self, month):
        return f"Q{((month - 1) // 3) + 1}"

    def quarterly_sales_report(self, sales_data):
        quarterly = defaultdict(lambda: {
            "total_sales": 0.0,
            "total_profit": 0.0,
            "departments": defaultdict(lambda: {"sales": 0.0, "profit": 0.0}),
            "top_orders": []
        })

        for data in sales_data:
            quarter = self.get_quarter(data.date_sold.month)
            sales = data.quantity_sold * data.unit_price
            cost = data.quantity_sold * data.base_cost
            profit = sales - cost

            q = quarterly[quarter]
            q["total_sales"] += sales
            q["total_profit"] += profit
            q["departments"][data.department_name]["sales"] += sales
            q["departments"][data.department_name]["profit"] += profit
            q["top_orders"].append({
                "product_id": data.product_id,
                "quantity_sold": data.quantity_sold,
                "unit_price": round(data.unit_price, 2),
                "total_sales": round(sales, 2),
                "profit": round(profit, 2)
            })

        for q in quarterly.values():
            q["profit_percentage"] = round((q["total_profit"] / q["total_sales"]) * 100, 2) if q["total_sales"] > 0 else 0
            q["top_orders"] = sorted(q["top_orders"], key=lambda o: o["profit"], reverse=True)[:3]
            q["departments"] = {
                dept: {
                    "sales": round(info["sales"], 2),
                    "profit": round(info["profit"], 2),
                    "profit_percentage": round((info["profit"] / info["sales"]) * 100, 2) if info["sales"] > 0 else 0
                } for dept, info in q["departments"].items()
            }

        return quarterly

@app.route("/report", methods=["GET"])
def get_report():
    report = QuarterlyIncomeReport()
    sales_data = report.generate_sales_data()
    result = report.quarterly_sales_report(sales_data)
    return jsonify(result)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
