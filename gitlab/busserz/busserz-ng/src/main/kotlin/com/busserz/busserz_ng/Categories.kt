package com.busserz.busserz_ng

import io.vertx.core.Future

data class Category(val id: String, val categoryName: String)

interface CategoryService {
  fun getCategory(id: String): Future<Category>
  fun addCategory(category: Category): Future<Unit>
  fun deleteCategory(id: String): Future<Unit>
  fun listCompanies(companyId: String): Future<HashMap<String, Category>>
}

class MemoryCategoryService : CategoryService {

  val _categories = HashMap<String, Category>()

  init {
    addCategory(Category("drinks", "Dricka"))
    addCategory(Category("food", "Mat"))
  }

  override fun getCategory(id: String): Future<Category> {
    return if (_categories.containsKey(id)) Future.succeededFuture(_categories[id])
    else Future.failedFuture(IllegalArgumentException("Unknown category $id"))
  }

  override fun addCategory(category: Category): Future<Unit> {
    _categories.put(category.id, category)
    return Future.succeededFuture()
  }

  override fun deleteCategory(id: String): Future<Unit> {
    _categories.remove(id)
    return Future.succeededFuture()
  }

  override fun listCompanies(companyId: String): Future<HashMap<String, Category>> {
    return if (!_categories.isEmpty()) Future.succeededFuture(_categories )
    else Future.failedFuture(IllegalArgumentException("No companies"))
  }
}
