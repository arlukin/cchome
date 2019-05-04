package com.busserz.busserz_ng.busserz_ng

import io.vertx.core.Future

data class Company(val id: String, val companyName: String, val Address: String)

interface CompanyService {
  fun getCompany(id: String): Future<Company>
  fun addCompany(company: Company): Future<Unit>
  fun deleteCompany(id: String): Future<Unit>
  fun listCompanies(): Future<HashMap<String, Company>>
}

class MemoryCompanyService() : CompanyService {

  val _companies = HashMap<String, Company>()

  init {
    addCompany(Company("addfood", "Addfood", "Telefonplan"))
    addCompany(Company("barasbacke", "Baras Backe", "Götgatan 34"))
  }

  override fun getCompany(id: String): Future<Company> {
    return if (_companies.containsKey(id)) Future.succeededFuture(_companies[id])
    else Future.failedFuture(IllegalArgumentException("Unknown company $id"))
  }

  override fun addCompany(company: Company): Future<Unit> {
    _companies.put(company.id, company)
    return Future.succeededFuture()
  }

  override fun deleteCompany(id: String): Future<Unit> {
    _companies.remove(id)
    return Future.succeededFuture()
  }

  override fun listCompanies(): Future<HashMap<String, Company>> {
    return if (!_companies.isEmpty()) Future.succeededFuture(_companies )
    else Future.failedFuture(IllegalArgumentException("No companies"))
  }
}
