// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

typedef struct referenceCountManager{
  struct spinlock lock;
  int pageRefCount[PHYSTOP >> 12];
}referenceCountManager;
referenceCountManager refcntmgr;

void initializePageReferenceCount(void) 
{
  initlock(&refcntmgr.lock,"refCount");
  acquire(&refcntmgr.lock);
  int pageCount=PHYSTOP >> 12;
  for(int i=0;i<pageCount;i++){
    refcntmgr.pageRefCount[i]=0;
  }
  release(&refcntmgr.lock);
}

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  initializePageReferenceCount();
  freerange(end, (void*)PHYSTOP);
}

int DecrementAndGetPageReference(void *pa) 
{
  acquire(&refcntmgr.lock);
  uint64 pageIdx=(uint64)pa >> 12;
  int refCount=refcntmgr.pageRefCount[pageIdx];
  if(refCount<=0){
    panic("DecrementAndGetPageReference");
  }
  refcntmgr.pageRefCount[pageIdx]--;
  release(&refcntmgr.lock);
  return refCount-1;  
}

int IncrementAndGetPageReference(void *pa) 
{
  acquire(&refcntmgr.lock);
  uint64 pageIdx=(uint64)pa >> 12;
  int refCount=refcntmgr.pageRefCount[pageIdx];
  if(refCount<0){
    panic("IncrementAndGetPageReference");
  }
  refcntmgr.pageRefCount[pageIdx]++;
  release(&refcntmgr.lock);
  return refCount+1;  
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    IncrementAndGetPageReference(p);
    kfree(p);
  }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  int refCount=DecrementAndGetPageReference(pa);
  if(refCount>0){
    return;
  }

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r){
    kmem.freelist = r->next;
    IncrementAndGetPageReference((void *)r);
  }
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
