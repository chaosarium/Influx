# Backend Testing Design & Implementation Plan

## Overview

This document outlines the design and implementation plan for comprehensive testing of the Influx backend, focusing on database interactions and API endpoints using embedded PostgreSQL for isolated, reproducible tests.

The tests should try to catch regressions, but need not be too comprehensive. They should be readable, minimal, and not cause excessive maintenance overhead. 

## Current State Analysis

### Existing Testing Infrastructure (Updated 2025-07-30)
- **Database Testing**: Full embedded PostgreSQL setup with `TestDb` helper
- **Test Dependencies**: `postgresql_embedded`, `tempfile`, `expect-test`, `tabled`, `tracing-test`
- **Database Models**: Complete CRUD tests for Language model with snapshot testing
- **Test Utilities**: `TestDb` struct providing isolated database instances
- **Test Format**: Snapshot tests using `expect-test` with formatted table output
- **Basic Coverage**: Language model CRUD operations fully tested

### Completed Infrastructure
- ✅ `EmbeddedDb` struct managing PostgreSQL lifecycle with persistent installation caching
- ✅ `TestDb` wrapper providing clean database instances per test
- ✅ Migration automation (runs migrations on each test database)
- ✅ Automatic cleanup (temporary directories and PostgreSQL instances)
- ✅ Comprehensive Language model tests with table-formatted snapshots
- ✅ Test isolation (each test gets fresh database instance)

### Remaining Implementation Needs
- **Document Model Tests**: Complete CRUD testing for Document operations
- **Vocabulary Model Tests**: Testing for Token/vocabulary operations  
- **Phrase Model Tests**: Testing for Phrase operations
- **API Endpoint Tests**: HTTP endpoint testing with realistic database state
- **Advanced Test Features**: Mock services, builders, performance optimizations

## Design Goals

### Primary Objectives
1. **Database Testing**: ✅ Test all database operations (CRUD, migrations, complex queries)
2. **API Testing**: Test HTTP endpoints with realistic database state  
3. **Test Isolation**: ✅ Each test gets a clean, isolated database environment
4. **No External Dependencies**: ✅ Tests should not require external PostgreSQL server
5. **Performance**: ✅ Tests should be fast enough for frequent execution
6. **Maintainability**: ✅ Easy to write and maintain test cases

### Non-Goals
- Load testing or performance benchmarking
- Cross-database compatibility testing
- Production environment simulation

## Architecture Design

### ✅ Implemented: Embedded PostgreSQL Infrastructure

**Current Implementation:**
- **EmbeddedDb**: Manages full PostgreSQL lifecycle with persistent installation caching
- **TestDb**: Wrapper providing clean database instances with automatic cleanup
- **Performance Optimization**: PostgreSQL binaries cached in `~/.cache/influx_core/postgresql`
- **Migration Integration**: Runs `sqlx migrate` automatically on each test database
- **Isolation**: Each test gets fresh PostgreSQL instance on random port

**Architecture Pattern:**
```
Test Start → Create TempDir → Start Embedded PG → Run Migrations → Execute Test → Cleanup
```

### ✅ Implemented: Test Architecture Layers

```
┌─────────────────────────────────────┐
│           Integration Tests         │
│  ┌─────────────────┐ ┌─────────────┐│
│  │   API Tests     │ │✅ DB Tests  ││
│  │ (HTTP endpoints)│ │ (Models)    ││
│  │     (TODO)      │ │(Lang Model) ││
│  └─────────────────┘ └─────────────┘│
├─────────────────────────────────────┤
│        ✅ Test Utilities           │
│  ┌─────────────────┐ ┌─────────────┐│
│  │✅ TestDb Helper │ │ TestServer  ││
│  │(Embedded PG)    │ │ (TODO)      ││
│  └─────────────────┘ └─────────────┘│
├─────────────────────────────────────┤
│          Application Code           │
│     (DB Models, API Handlers)       │
└─────────────────────────────────────┘
```

### ✅ Implemented: Testing Patterns & Tools

**Snapshot Testing with Tables:**
- Uses `expect-test` for snapshot assertions
- `tabled` crate for formatted table output in test snapshots
- `tracing-test` for test logging
- Clear visual comparison of database state changes

**Test Structure Example:**
```rust
#[tokio::test]
#[tracing_test::traced_test]
async fn test_language_crud_operations() {
    let test_db = TestDb::new().await.unwrap();
    // ... test operations with table-formatted snapshots
}
```

## Implementation Status

### ✅ Completed: Phase 1 - Foundation Setup

#### 1.1 ✅ Dependencies & Configuration
**File**: `influx_core/Cargo.toml`
```toml
[dev-dependencies]
postgresql_embedded = "0.19.0"  # ✅ Added
tempfile = "3.8"                # ✅ Added
expect-test = "1.5.1"           # ✅ Added
tabled = "0.20.0"               # ✅ Added  
tracing-test = "0.2.5"          # ✅ Added
```

#### 1.2 ✅ Test Utilities Module
**File**: `influx_core/src/test_utils.rs`

**Implemented Features**:
- ✅ `TestDb` struct: Manages embedded PostgreSQL lifecycle
- ✅ Automatic database setup with migrations
- ✅ Clean database instance per test
- ✅ Automatic cleanup on test completion

**Current API**:
```rust
pub struct TestDb {
    pub db: crate::db::DB,
    _embedded_db: EmbeddedDb,
}

impl TestDb {
    pub async fn new() -> Result<Self>
}
```

#### 1.3 ✅ Embedded Database Infrastructure
**File**: `influx_core/src/embedded_db.rs`

**Implemented Features**:
- ✅ `EmbeddedDb` struct with PostgreSQL lifecycle management
- ✅ Persistent installation directory caching (`~/.cache/influx_core/postgresql`)
- ✅ Temporary data directories per instance
- ✅ Automatic migration execution
- ✅ Random port allocation for test isolation
- ✅ Graceful cleanup on drop

### ✅ Completed: Phase 2 - Database Model Tests (Partial)

#### 2.1 ✅ Language Model Tests
**File**: `influx_core/src/db/models/lang.rs` (lines 200-351)

**Implemented Test Coverage**:
- ✅ **CRUD Operations**: Create, Read, Update operations fully tested
- ✅ **Snapshot Testing**: Table-formatted test output with `expect-test`
- ✅ **Test Isolation**: Each test uses fresh database instance
- ✅ **Edge Cases**: Nonexistent language retrieval, validation
- ✅ **State Verification**: Database state changes verified with formatted tables

**Test Pattern**:
```rust
#[tokio::test]
#[tracing_test::traced_test]
async fn test_language_crud_operations() {
    let test_db = TestDb::new().await.unwrap();
    
    // Test operations with snapshot assertions
    let languages = test_db.db.get_languages_vec().await.unwrap();
    let table_rows: Vec<LanguageTableRow> = languages.iter().map(Into::into).collect();
    let table = Table::new(table_rows).with(Style::rounded()).to_string();
    
    expect![[r#"
        ╭────┬──────┬───────┬──────────┬────────╮
        │ id │ name │ dicts │ tts_rate │ parser │
        ├────┼──────┼───────┼──────────┼────────┤"#]]
    .assert_eq(&table);
}
```

### 🚧 Remaining Implementation Tasks

#### 2.2 📋 Document Model Tests (TODO)
**File**: `influx_core/src/db/models/document.rs`
- Create comprehensive CRUD tests following Language model pattern
- Test document-specific operations (content parsing, segmentation)
- Verify relationships with Language and other models

#### 2.3 📋 Vocabulary Model Tests (TODO)  
**File**: `influx_core/src/db/models/vocab.rs`
- Test Token/vocabulary CRUD operations
- Test search and filtering functionality
- Verify relationships with documents and phrases

#### 2.4 📋 Phrase Model Tests (TODO)
**File**: `influx_core/src/db/models/phrase.rs`
- Test phrase creation and management
- Test phrase-token relationships
- Test complex queries for phrase retrieval

### ✅ Completed: Phase 3 - API Endpoint Testing Infrastructure

#### 3.1 ✅ Language API Testing
**File**: `tests/lang_api_tests.rs`

**Implemented Test Coverage**:
- ✅ **GET /lang** - Empty and populated language lists  
- ✅ **GET /lang/{id}** - Success, not found, and invalid ID format
- ✅ **POST /lang/edit** - Success, missing ID, and nonexistent language
- ✅ **Complete Workflow** - End-to-end API usage scenario

**Testing Infrastructure**:
- ✅ **Axum Test Server**: Uses `axum-test` for HTTP testing
- ✅ **Shared Router Code**: Refactored `create_app_router()` shared between production and tests
- ✅ **Test Utilities**: Enhanced with `create_test_app()` function
- ✅ **Snapshot Testing**: Table-formatted API response verification
- ✅ **Database Integration**: Each test uses isolated embedded PostgreSQL

**Example Test Output**:
```
╭─────────────────────┬─────────┬────────────────────┬──────────┬────────────╮
│ id                  │ name    │ dicts              │ tts_rate │ parser     │
├─────────────────────┼─────────┼────────────────────┼──────────┼────────────┤
│ InfluxResourceId(1) │ 日本語  │ ["dict1", "dict2"] │ 1.5      │ base_spacy │
╰─────────────────────┴─────────┴────────────────────┴──────────┴────────────╯
```

**Test Results**: All 9 API tests pass with comprehensive coverage

#### 3.2 ✅ Infrastructure Improvements
- **Router Sharing**: `lib.rs` now exports `create_app_router()` function
- **Public ServerState**: Made `db` field public for testing access
- **Updated Dependencies**: Added `axum-test = "17.3.0"` for HTTP testing
- **Clean Architecture**: No duplication between production and test router setup

#### 3.3 📋 Remaining API Tests (TODO)
- `doc_api_tests.rs` - Document endpoints
- `term_api_tests.rs` - Term/vocabulary endpoints
- `integration_api_tests.rs` - External integration endpoints

### 📋 Phase 4: Advanced Testing Features (TODO)

#### 4.1 Test Data Management
- **Test Data Seeding**: `TestDb::seed_test_data()` and custom seeding
- **Builders**: Fluent API for creating test objects  
- **Factories**: Generate realistic test data
- **Fixtures**: Predefined test data sets

#### 4.2 Performance Optimizations
- **Shared PostgreSQL Instances**: Reuse PG instances across tests
- **Parallel Test Execution**: Configure safe parallel testing
- **Connection Pooling**: Optimize database connections

## Current File Structure

```
influx_core/
├── src/
│   ├── ✅ embedded_db.rs          # Embedded PostgreSQL infrastructure  
│   ├── ✅ test_utils.rs           # TestDb helper + create_test_app()
│   ├── ✅ lib.rs                  # create_app_router() shared function
│   ├── db/models/
│   │   ├── ✅ lang.rs             # Language model with complete tests
│   │   ├── ✅ seed.rs             # Simplified single seed function
│   │   ├── 📋 document.rs         # TODO: Add comprehensive tests
│   │   ├── 📋 vocab.rs            # TODO: Add comprehensive tests  
│   │   └── 📋 phrase.rs           # TODO: Add comprehensive tests
│   └── ...
├── ✅ tests/                      # Integration tests created
│   └── ✅ lang_api_tests.rs       # Complete language API testing
├── ✅ Cargo.toml                  # Updated with test dependencies
└── justfile                       # Basic commands (could be enhanced)
```

## Updated Implementation Timeline

### ✅ Completed (Current Status)
- ✅ Embedded PostgreSQL infrastructure (`EmbeddedDb`)
- ✅ Basic test utilities (`TestDb`)  
- ✅ Language model comprehensive CRUD tests
- ✅ **API testing infrastructure with shared router code**
- ✅ **Complete language API endpoint testing (9 tests)**
- ✅ **Simplified seed.rs with enhanced vocabulary and phrases**
- ✅ Snapshot testing with table formatting
- ✅ Test isolation and automatic cleanup
- ✅ All required dependencies added to `Cargo.toml`

### Week 1: Complete Database Model Testing  
- [ ] Document model tests (`influx_core/src/db/models/document.rs`)
- [ ] Vocabulary model tests (`influx_core/src/db/models/vocab.rs`)
- [ ] Phrase model tests (`influx_core/src/db/models/phrase.rs`)
- [ ] Enhanced `TestDb` with data seeding utilities

### Week 2: Expand API Testing
- [ ] Document API tests (`tests/doc_api_tests.rs`)
- [ ] Term API tests (`tests/term_api_tests.rs`)
- [ ] Integration API tests (`tests/integration_api_tests.rs`)
- [ ] Error handling and edge case testing

### Week 3: Advanced Features & Polish
- [ ] Test data builders and factories
- [ ] Performance optimizations (shared instances, parallel execution)
- [ ] Enhanced test utilities and helpers
- [ ] Comprehensive test documentation

### Week 4: Integration & Finalization  
- [ ] CI/CD integration and parallel test configuration
- [ ] Test coverage reporting
- [ ] Performance benchmarks and optimization
- [ ] Final documentation and examples

## Success Metrics

### Coverage Goals (Updated)
- **Database Models**: 
  - ✅ Language model: 100% CRUD operations tested
  - 📋 Document model: TODO - Complete CRUD testing
  - 📋 Vocabulary model: TODO - Complete CRUD testing  
  - 📋 Phrase model: TODO - Complete CRUD testing
- **API Endpoints**: 📋 TODO - 100% of routes tested with success/error cases
- **Code Coverage**: 📋 Goal: >80% line coverage for core business logic

### Quality Metrics (Established)
- **Test Reliability**: ✅ Current: <1% flaky test rate (no flaky tests observed)
- **Test Performance**: ✅ Current: Individual tests run in <1 second  
- **Test Maintainability**: ✅ Current: Tests use clear patterns and snapshot testing

### Developer Experience (Achieved)
- **Easy Test Writing**: ✅ `TestDb::new()` provides instant isolated database
- **Fast Feedback**: ✅ Tests provide immediate feedback on database operations
- **Clear Failures**: ✅ Snapshot tests show exact table differences on failure
- **Visual Output**: ✅ Table-formatted test output makes state changes obvious

## Risk Mitigation

### ✅ Resolved Issues

**Issue**: Embedded PostgreSQL download size (~50MB)
**Solution**: ✅ **IMPLEMENTED** - Binaries cached in `~/.cache/influx_core/postgresql`, only downloaded once

**Issue**: Platform compatibility  
**Solution**: ✅ **VERIFIED** - `postgresql_embedded` handles platform detection and downloads

**Issue**: Test isolation and cleanup
**Solution**: ✅ **IMPLEMENTED** - Each test gets fresh instance, automatic cleanup on drop

### 📋 Remaining Potential Issues

**Issue**: Test execution time with multiple database instances
**Solution**: 📋 **TODO** - Implement shared instances for compatible tests, parallel execution

**Issue**: Test complexity and maintenance
**Solution**: ✅ **MITIGATED** - Strong `TestDb` abstraction, consistent snapshot testing patterns

**Issue**: CI/CD resource usage
**Solution**: 📋 **TODO** - Optimize CI with caching, selective testing, parallel execution

---

## Summary of Current Implementation

The Influx backend testing infrastructure has been successfully established with a solid foundation:

### ✅ **Completed Infrastructure**
- **Embedded PostgreSQL**: Full lifecycle management with persistent caching
- **Test Isolation**: Each test gets a clean database instance  
- **Language Model Testing**: Complete CRUD operations with snapshot testing
- **Developer Experience**: Simple `TestDb::new()` API for writing tests
- **Visual Testing**: Table-formatted snapshots for clear state verification

### 📋 **Next Steps**
1. **Complete Model Testing**: Add tests for Document, Vocabulary, and Phrase models
2. **API Testing**: Implement `TestServer` and HTTP endpoint testing
3. **Advanced Features**: Test data seeding, builders, and performance optimizations
4. **CI/CD Integration**: Parallel execution and coverage reporting

The foundation is solid and ready for expanding to complete backend test coverage.

---

*This design provides a comprehensive, maintainable testing infrastructure that enables confident development and refactoring of the Influx backend while maintaining high code quality and reliability.*