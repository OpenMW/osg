# Check for availability of atomic operations
# This module defines
# OPENTHREADS_HAVE_ATOMIC_OPS

OPTION(OPENTHREADS_ATOMIC_USE_MUTEX "Set to ON to force OpenThreads to use a mutex for Atmoic." OFF)

IF (OPENTHREADS_ATOMIC_USE_MUTEX)

    SET(_OPENTHREADS_ATOMIC_USE_STD_ATOMIC 0)
    SET(_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS 0)
    SET(_OPENTHREADS_ATOMIC_USE_MIPOSPRO_BUILTINS 0)
    SET(_OPENTHREADS_ATOMIC_USE_SUN 0)
    SET(_OPENTHREADS_ATOMIC_USE_WIN32_INTERLOCKED 0)
    SET(_OPENTHREADS_ATOMIC_USE_BSD_ATOMIC 0)

    SET(_OPENTHREADS_ATOMIC_USE_MUTEX 1)

ELSE()
    # as the test does not work for IOS hardcode the ATOMIC implementation
    IF(OSG_BUILD_PLATFORM_IPHONE_SIMULATOR OR OSG_BUILD_PLATFORM_IPHONE)
       SET(_OPENTHREADS_ATOMIC_USE_STD_ATOMIC 0)
       SET(_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS 0)
       SET(_OPENTHREADS_ATOMIC_USE_MIPOSPRO_BUILTINS 0)
       SET(_OPENTHREADS_ATOMIC_USE_SUN 0)
       SET(_OPENTHREADS_ATOMIC_USE_WIN32_INTERLOCKED 0)
       SET(_OPENTHREADS_ATOMIC_USE_MUTEX 0)

       SET(_OPENTHREADS_ATOMIC_USE_BSD_ATOMIC 1)

    ELSE()
       INCLUDE(CheckCXXSourceCompiles)

       # Do step by step checking,
       check_cxx_source_compiles("
       #include <atomic>
       #include <cstdlib>

       int main()
       {
          std::atomic<unsigned> value{0};
          std::atomic<void*> ptr{nullptr};
          value.fetch_add(1, std::memory_order_acq_rel);
          std::atomic_thread_fence(std::memory_order_seq_cst);
          value.fetch_sub(1, std::memory_order_acq_rel);
          unsigned expected = 0;

          if (!value.compare_exchange_strong(expected, 1))
             return EXIT_FAILURE;

          void* expected_ptr = nullptr;
          void* new_ptr = &value;

          if (!ptr.compare_exchange_strong(expected_ptr, new_ptr))
             return EXIT_FAILURE;

          return EXIT_SUCCESS;
       }
       " _OPENTHREADS_ATOMIC_USE_STD_ATOMIC)

       check_cxx_source_compiles("
       #include <cstdlib>

       int main()
       {
          unsigned value = 0;
          void* ptr = &value;
          __sync_add_and_fetch(&value, 1);
          __sync_synchronize();
          __sync_sub_and_fetch(&value, 1);
          if (!__sync_bool_compare_and_swap(&value, 0, 1))
             return EXIT_FAILURE;

          if (!__sync_bool_compare_and_swap(&ptr, ptr, ptr))
             return EXIT_FAILURE;

          return EXIT_SUCCESS;
       }
       " _OPENTHREADS_ATOMIC_USE_GCC_BUILTINS)

       check_cxx_source_compiles("
       #include <stdlib.h>

       int main(int, const char**)
       {
          unsigned value = 0;
          void* ptr = &value;
          __add_and_fetch(&value, 1);
          __synchronize(value);
          __sub_and_fetch(&value, 1);
          if (!__compare_and_swap(&value, 0, 1))
             return EXIT_FAILURE;

          if (!__compare_and_swap((unsigned long*)&ptr, (unsigned long)ptr, (unsigned long)ptr))
             return EXIT_FAILURE;

          return EXIT_SUCCESS;
       }
       " _OPENTHREADS_ATOMIC_USE_MIPOSPRO_BUILTINS)

       check_cxx_source_compiles("
       #include <atomic.h>
       #include <cstdlib>

       int main(int, const char**)
       {
          uint_t value = 0;
          void* ptr = &value;
          atomic_inc_uint_nv(&value);
          membar_consumer();
          atomic_dec_uint_nv(&value);
          if (0 != atomic_cas_uint(&value, 0, 1))
             return EXIT_FAILURE;

          if (ptr != atomic_cas_ptr(&ptr, ptr, ptr))
             return EXIT_FAILURE;

          return EXIT_SUCCESS;
       }
       " _OPENTHREADS_ATOMIC_USE_SUN)

       check_cxx_source_compiles("
       #include <windows.h>
       #include <intrin.h>
       #include <cstdlib>

       #pragma intrinsic(_InterlockedAnd)
       #pragma intrinsic(_InterlockedOr)
       #pragma intrinsic(_InterlockedXor)

       int main(int, const char**)
       {
          volatile long value = 0;
          long data = 0;
          long* volatile ptr = &data;

          InterlockedIncrement(&value);
          MemoryBarrier();
          InterlockedDecrement(&value);

          if (0 != InterlockedCompareExchange(&value, 1, 0))
             return EXIT_FAILURE;

          if (ptr != InterlockedCompareExchangePointer((PVOID volatile*)&ptr, (PVOID)ptr, (PVOID)ptr))
             return EXIT_FAILURE;

          return EXIT_SUCCESS;
       }
       " _OPENTHREADS_ATOMIC_USE_WIN32_INTERLOCKED)

       check_cxx_source_compiles("
       #include <libkern/OSAtomic.h>

       int main()
       {
         volatile int32_t value = 0;
         long data = 0;
         long * volatile ptr = &data;

         OSAtomicIncrement32(&value);
         OSMemoryBarrier();
         OSAtomicDecrement32(&value);
         OSAtomicCompareAndSwapInt(value, 1, &value);
         OSAtomicCompareAndSwapPtr(ptr, ptr, (void * volatile *)&ptr);
       }
       " _OPENTHREADS_ATOMIC_USE_BSD_ATOMIC)

       IF(NOT _OPENTHREADS_ATOMIC_USE_STD_ATOMIC AND
          NOT _OPENTHREADS_ATOMIC_USE_GCC_BUILTINS AND
          NOT _OPENTHREADS_ATOMIC_USE_MIPOSPRO_BUILTINS AND
          NOT _OPENTHREADS_ATOMIC_USE_SUN AND
          NOT _OPENTHREADS_ATOMIC_USE_WIN32_INTERLOCKED AND
          NOT _OPENTHREADS_ATOMIC_USE_BSD_ATOMIC)
                  SET(_OPENTHREADS_ATOMIC_USE_MUTEX 1)
       ENDIF()

       
       # MinGW can set both WIN32_INTERLOCKED and GCC_BUILTINS to true which results in compliation errors
       IF (_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS AND _OPENTHREADS_ATOMIC_USE_WIN32_INTERLOCKED)
          # In this case we prefer the GCC_BUILTINS
          SET(_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS 1)
          SET(_OPENTHREADS_ATOMIC_USE_WIN32_INTERLOCKED 0)
       ELSEIF (_OPENTHREADS_ATOMIC_USE_STD_ATOMIC AND _OPENTHREADS_ATOMIC_USE_WIN32_INTERLOCKED)
           SET(_OPENTHREADS_ATOMIC_USE_STD_ATOMIC 1)
           SET(_OPENTHREADS_ATOMIC_USE_WIN32_INTERLOCKED 0)
       ENDIF()

    ENDIF()

ENDIF()
