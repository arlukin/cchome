package com.busserz.busserz_ng

import io.vertx.core.Future

data class Product(val id: String, val productName: String, val description: String, val price: Int)

interface ProductService {
  fun getProduct(companyId: String, categoryId: String, productId: String): Future<Product>
  fun addProduct(product: Product): Future<Unit>
  fun deleteProduct(id: String): Future<Unit>
  fun listProducts(companyId: String, categoryId: String): Future<HashMap<String, Product>>
}

class MemoryProductService : ProductService {

  val _products = HashMap<String, Product>()

  init {
    addProduct(Product("carlsberg", "Carlsberg", "En god öl", 40))
    addProduct(Product("hamburger", "Hamburgare", "105% vegan", 105))
  }

  override fun getProduct(companyId: String, categoryId: String, productId: String): Future<Product> {
    return if (_products.containsKey(productId)) Future.succeededFuture(_products[productId])
    else Future.failedFuture(IllegalArgumentException("Unknown product $productId"))
  }

  override fun addProduct(product: Product): Future<Unit> {
    _products.put(product.id, product)
    return Future.succeededFuture()
  }

  override fun deleteProduct(id: String): Future<Unit> {
    _products.remove(id)
    return Future.succeededFuture()
  }

  override fun listProducts(companyId: String, categoryId: String): Future<HashMap<String, Product>> {
    return if (!_products.isEmpty()) Future.succeededFuture(_products )
    else Future.failedFuture(IllegalArgumentException("No products"))
  }
}
