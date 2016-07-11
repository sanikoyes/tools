#ifndef __TYPEDEF_H__
#define __TYPEDEF_H__

typedef double real_t;

#define Math_PI 3.14159265358979323846
#define Math_SQRT12 0.7071067811865475244008443621048490

#ifndef MIN
#define MIN(m_a,m_b) (((m_a)<(m_b))?(m_a):(m_b))
#endif

#ifndef MAX
#define MAX(m_a,m_b) (((m_a)>(m_b))?(m_a):(m_b))
#endif

#endif
