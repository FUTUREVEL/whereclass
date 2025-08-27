import { 
  collection, 
  getDocs, 
  doc, 
  getDoc,
  query,
  where,
  orderBy,
  limit
} from 'firebase/firestore';
import { db } from './firebase.js';

// 모든 데이터 조회
export async function getAllData(collectionName) {
  try {
    const querySnapshot = await getDocs(collection(db, collectionName));
    const data = [];
    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() });
    });
    return data;
  } catch (error) {
    console.error("데이터 조회 오류: ", error);
    throw error;
  }
}

// 특정 문서 조회
export async function getData(collectionName, docId) {
  try {
    const docRef = doc(db, collectionName, docId);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() };
    } else {
      console.log("문서를 찾을 수 없습니다!");
      return null;
    }
  } catch (error) {
    console.error("문서 조회 오류: ", error);
    throw error;
  }
}

// 조건부 쿼리
export async function getDataWhere(collectionName, field, operator, value) {
  try {
    const q = query(
      collection(db, collectionName),
      where(field, operator, value)
    );
    const querySnapshot = await getDocs(q);
    const data = [];
    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() });
    });
    return data;
  } catch (error) {
    console.error("조건부 쿼리 오류: ", error);
    throw error;
  }
}

// 정렬된 데이터 조회
export async function getDataOrdered(collectionName, orderField, direction = 'asc') {
  try {
    const q = query(
      collection(db, collectionName),
      orderBy(orderField, direction)
    );
    const querySnapshot = await getDocs(q);
    const data = [];
    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() });
    });
    return data;
  } catch (error) {
    console.error("정렬된 데이터 조회 오류: ", error);
    throw error;
  }
}

// 제한된 개수의 데이터 조회
export async function getDataLimited(collectionName, limitCount) {
  try {
    const q = query(
      collection(db, collectionName),
      limit(limitCount)
    );
    const querySnapshot = await getDocs(q);
    const data = [];
    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() });
    });
    return data;
  } catch (error) {
    console.error("제한된 데이터 조회 오류: ", error);
    throw error;
  }
}

// 복합 쿼리 (조건 + 정렬 + 제한)
export async function getDataComplex(collectionName, whereConditions = [], orderField = null, direction = 'asc', limitCount = null) {
  try {
    let q = collection(db, collectionName);
    
    // where 조건들 추가
    if (whereConditions.length > 0) {
      const constraints = whereConditions.map(condition => 
        where(condition.field, condition.operator, condition.value)
      );
      q = query(q, ...constraints);
    }
    
    // 정렬 추가
    if (orderField) {
      q = query(q, orderBy(orderField, direction));
    }
    
    // 제한 추가
    if (limitCount) {
      q = query(q, limit(limitCount));
    }
    
    const querySnapshot = await getDocs(q);
    const data = [];
    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() });
    });
    return data;
  } catch (error) {
    console.error("복합 쿼리 오류: ", error);
    throw error;
  }
}