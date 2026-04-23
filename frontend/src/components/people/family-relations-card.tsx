/**
 * @project AncestorTree
 * @file src/components/people/family-relations-card.tsx
 * @description Card showing family relations (parents, siblings, spouse, children) for a person
 * @version 1.0.0
 * @updated 2026-02-25
 */

'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { toast } from 'sonner';
import {
  usePersonRelations,
  useCreateSpouseFamily,
  useAddChildToFamilyMutation,
  useUpdateFamily,
  useUpdateChild,
  useRemoveChildFromFamily,
  useAddPersonToParentFamily,
} from '@/hooks/use-families';
import { useSearchPeople, useCreatePerson } from '@/hooks/use-people';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { Skeleton } from '@/components/ui/skeleton';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Users, Plus, Search, UserPlus, Eye, Edit2, Trash2, MoreVertical } from 'lucide-react';
import type { Person, Family, PersonRelations } from '@/types';
import { useGenerationOffset, displayGen } from '@/hooks/use-generation-offset';

// ─── PersonLink ───────────────────────────────────────────────────────────────

function PersonLink({ 
  person, 
  actions 
}: { 
  person: Person; 
  actions?: React.ReactNode; 
}) {
  const isMale = person.gender === 1;
  const isFemale = person.gender === 2;
  const isLiving = person.is_living;
  const offset = useGenerationOffset();

  let avatarBgClass = isMale ? 'bg-blue-100 text-blue-700' : 'bg-pink-100 text-pink-700';
  if (!isLiving) {
    avatarBgClass = 'bg-gray-600 text-white';
  }

  const nameColorClass = isMale ? 'text-blue-600' : (isFemale ? 'text-pink-600' : '');

  return (
    <div className="flex items-center gap-1 group">
      <Link
        href={`/people/${person.id}`}
        className="flex-1 flex items-center gap-2 hover:bg-muted rounded-md px-2 py-1 transition-colors"
      >
        <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold shrink-0 ${avatarBgClass}`}>
          {person.display_name.slice(-1)}
        </div>
        <span className={`text-sm font-bold group-hover:opacity-80 transition-opacity ${nameColorClass}`}>
          {person.display_name}
        </span>
        {person.birth_year && (
          <span className="text-xs text-muted-foreground">({person.birth_year})</span>
        )}
        {!isLiving && <span className="text-xs text-muted-foreground">†</span>}
        <span className="text-xs text-muted-foreground ml-auto">Đời {displayGen(person.generation, offset)}</span>
      </Link>
      {actions}
    </div>
  );
}

function RelationActions({
  personId,
  canEdit,
  onEdit,
  onDelete,
}: {
  personId: string;
  canEdit: boolean;
  onEdit?: () => void;
  onDelete?: () => void;
}) {
  return (
    <div className="flex items-center opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
      <Button variant="ghost" size="icon" className="h-7 w-7" asChild title="Xem chi tiết">
        <Link href={`/people/${personId}`}>
          <Eye className="h-3.5 w-3.5" />
        </Link>
      </Button>
      {canEdit && onEdit && (
        <Button variant="ghost" size="icon" className="h-7 w-7" onClick={onEdit} title="Sửa quan hệ">
          <Edit2 className="h-3.5 w-3.5 text-blue-600" />
        </Button>
      )}
      {canEdit && onDelete && (
        <Button variant="ghost" size="icon" className="h-7 w-7" onClick={onDelete} title="Xóa quan hệ">
          <Trash2 className="h-3.5 w-3.5 text-red-600" />
        </Button>
      )}
    </div>
  );
}


// ─── QuickPersonForm ─────────────────────────────────────────────────────────

interface QuickPersonData {
  display_name: string;
  gender: 1 | 2;
  birth_year: string;
  generation: number;
}

interface QuickPersonFormProps {
  defaultGender?: 1 | 2;
  defaultGeneration: number;
  onSubmit: (data: QuickPersonData) => Promise<void>;
  isLoading: boolean;
}

function QuickPersonForm({
  defaultGender = 1,
  defaultGeneration,
  onSubmit,
  isLoading,
}: QuickPersonFormProps) {
  const [name, setName] = useState('');
  const [gender, setGender] = useState<1 | 2>(defaultGender);
  const [birthYear, setBirthYear] = useState('');
  const [generation, setGeneration] = useState(defaultGeneration);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    await onSubmit({
      display_name: name.trim(),
      gender,
      birth_year: birthYear,
      generation,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      <div className="space-y-1">
        <Label htmlFor="qf-name">Tên *</Label>
        <Input
          id="qf-name"
          placeholder="Nguyễn Văn A"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
        />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-1">
          <Label>Giới tính</Label>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => setGender(1)}
              className={`flex-1 py-1.5 rounded text-sm border ${
                gender === 1
                  ? 'bg-blue-50 border-blue-400 text-blue-700 font-medium'
                  : 'border-muted-foreground/30'
              }`}
            >
              Nam
            </button>
            <button
              type="button"
              onClick={() => setGender(2)}
              className={`flex-1 py-1.5 rounded text-sm border ${
                gender === 2
                  ? 'bg-pink-50 border-pink-400 text-pink-700 font-medium'
                  : 'border-muted-foreground/30'
              }`}
            >
              Nữ
            </button>
          </div>
        </div>
        <div className="space-y-1">
          <Label htmlFor="qf-year">Năm sinh</Label>
          <Input
            id="qf-year"
            placeholder="1980"
            type="number"
            value={birthYear}
            onChange={(e) => setBirthYear(e.target.value)}
          />
        </div>
      </div>
      <div className="space-y-1">
        <Label htmlFor="qf-gen">Đời</Label>
        <Input
          id="qf-gen"
          type="number"
          min={1}
          max={20}
          value={generation}
          onChange={(e) => setGeneration(Number(e.target.value))}
        />
      </div>
      <Button type="submit" className="w-full" disabled={isLoading || !name.trim()}>
        {isLoading ? 'Đang lưu...' : 'Lưu'}
      </Button>
    </form>
  );
}

// ─── PersonSearchSelect ───────────────────────────────────────────────────────

interface PersonSearchSelectProps {
  excludeIds?: string[];
  onSelect: (person: Person) => Promise<void>;
  isLoading: boolean;
}

function PersonSearchSelect({ excludeIds = [], onSelect, isLoading }: PersonSearchSelectProps) {
  const [query, setQuery] = useState('');
  const { data: results, isFetching } = useSearchPeople(query);
  const offset = useGenerationOffset();

  const filtered = (results || []).filter((p) => !excludeIds.includes(p.id));

  return (
    <div className="space-y-3">
      <div className="relative">
        <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Tìm theo tên... (nhập ít nhất 2 ký tự)"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="pl-9"
        />
      </div>
      {isFetching && <p className="text-sm text-muted-foreground">Đang tìm...</p>}
      {!isFetching && query.length >= 2 && filtered.length === 0 && (
        <p className="text-sm text-muted-foreground">Không tìm thấy kết quả</p>
      )}
      <div className="space-y-1 max-h-48 overflow-y-auto">
        {filtered.map((person) => (
          <button
            key={person.id}
            type="button"
            disabled={isLoading}
            onClick={() => onSelect(person)}
            className="w-full text-left flex items-center gap-2 px-3 py-2 rounded-md hover:bg-muted transition-colors disabled:opacity-50"
          >
            <div
              className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold shrink-0 ${
                !person.is_living 
                  ? 'bg-gray-600 text-white' 
                  : (person.gender === 1 ? 'bg-blue-100 text-blue-700' : 'bg-pink-100 text-pink-700')
              }`}
            >
              {person.display_name.slice(-1)}
            </div>
            <div>
              <p className={`text-sm font-bold ${person.gender === 1 ? 'text-blue-600' : (person.gender === 2 ? 'text-pink-600' : '')}`}>
                {person.display_name}
              </p>
              <p className="text-xs text-muted-foreground">
                Đời {displayGen(person.generation, offset)}{person.birth_year ? ` · ${person.birth_year}` : ''}
              </p>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

// ─── RelationDialog ───────────────────────────────────────────────────────────

type DialogMode = 'father' | 'mother' | 'spouse' | 'child';

interface RelationDialogProps {
  open: boolean;
  onClose: () => void;
  mode: DialogMode;
  currentPerson: Person;
  targetFamilyId?: string; // for child/spouse mode: which family to add to
  isUpdate?: boolean;
  oldPersonId?: string;
  onSuccess: () => void;
}

function RelationDialog({
  open,
  onClose,
  mode,
  currentPerson,
  targetFamilyId,
  isUpdate = false,
  oldPersonId,
  onSuccess,
}: RelationDialogProps) {
  const [tab, setTab] = useState<'new' | 'existing'>('new');
  const [isSaving, setIsSaving] = useState(false);
  const createPersonMutation = useCreatePerson();
  const createSpouseFamilyMutation = useCreateSpouseFamily();
  const addChildMutation = useAddChildToFamilyMutation(currentPerson.id);
  const updateFamilyMutation = useUpdateFamily();
  const updateChildMutation = useUpdateChild();
  const addPersonToParentFamilyMutation = useAddPersonToParentFamily();

  const defaultGender: 1 | 2 = (mode === 'spouse' || mode === 'mother')
    ? (currentPerson.gender === 1 ? 2 : 1)
    : 1;
  const defaultGeneration = (mode === 'spouse' || mode === 'father' || mode === 'mother')
    ? currentPerson.generation
    : currentPerson.generation + 1;

  const generateHandle = (name: string) => {
    return `${name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '')}-${Date.now()}`;
  };

  const handleCreateNew = async (data: QuickPersonData) => {
    setIsSaving(true);
    try {
      const newPerson = await createPersonMutation.mutateAsync({
        handle: generateHandle(data.display_name),
        display_name: data.display_name,
        gender: data.gender,
        generation: data.generation,
        birth_year: data.birth_year ? Number(data.birth_year) : undefined,
        is_living: true,
        is_patrilineal: data.gender === 1,
        privacy_level: 0,
      });

      await handleSelectExisting(newPerson);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Lỗi khi lưu');
    } finally {
      setIsSaving(false);
    }
  };

  const handleSelectExisting = async (person: Person) => {
    setIsSaving(true);
    try {
      if (isUpdate) {
        if (mode === 'child') {
          if (!targetFamilyId || !oldPersonId) throw new Error('Thiếu thông tin cập nhật con');
          await updateChildMutation.mutateAsync({
            familyId: targetFamilyId,
            oldPersonId: oldPersonId,
            newPersonId: person.id,
          });
        } else if (mode === 'father' || mode === 'mother' || mode === 'spouse') {
          if (!targetFamilyId) throw new Error('Thiếu thông tin gia đình');
          const field = mode === 'father' ? 'father_id' : (mode === 'mother' ? 'mother_id' : (currentPerson.gender === 1 ? 'mother_id' : 'father_id'));
          await updateFamilyMutation.mutateAsync({
            id: targetFamilyId,
            input: { [field]: person.id },
          });
        }
      } else {
        // Create mode
        if (mode === 'spouse') {
          await createSpouseFamilyMutation.mutateAsync({
            personId: currentPerson.id,
            personGender: currentPerson.gender,
            spouseId: person.id,
          });
        } else if (mode === 'child') {
          if (!targetFamilyId) throw new Error('Thiếu thông tin gia đình để thêm con');
          await addChildMutation.mutateAsync({
            familyId: targetFamilyId,
            childPersonId: person.id,
            sortOrder: 99,
          });
        } else if (mode === 'father' || mode === 'mother') {
          await addPersonToParentFamilyMutation.mutateAsync({
            fatherId: mode === 'father' ? person.id : null,
            motherId: mode === 'mother' ? person.id : null,
            childPersonId: currentPerson.id,
          });
        }
      }

      toast.success(isUpdate ? 'Đã cập nhật quan hệ' : 'Đã thêm quan hệ');
      onSuccess();
      onClose();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Lỗi khi lưu');
    } finally {
      setIsSaving(false);
    }
  };

  const modeLabel = {
    father: 'cha',
    mother: 'mẹ',
    spouse: currentPerson.gender === 1 ? 'vợ' : 'chồng',
    child: 'con',
  }[mode];

  const title = isUpdate
    ? `Sửa ${modeLabel} cho ${currentPerson.display_name}`
    : `Thêm ${modeLabel} cho ${currentPerson.display_name}`;

  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>

        <Tabs value={tab} onValueChange={(v) => setTab(v as 'new' | 'existing')}>
          <TabsList className="w-full">
            <TabsTrigger value="new" className="flex-1">
              <UserPlus className="h-4 w-4 mr-2" />
              Tạo mới
            </TabsTrigger>
            <TabsTrigger value="existing" className="flex-1">
              <Search className="h-4 w-4 mr-2" />
              Chọn có sẵn
            </TabsTrigger>
          </TabsList>

          <TabsContent value="new" className="mt-4">
            <QuickPersonForm
              defaultGender={defaultGender}
              defaultGeneration={defaultGeneration}
              onSubmit={handleCreateNew}
              isLoading={isSaving}
            />
          </TabsContent>

          <TabsContent value="existing" className="mt-4">
            <PersonSearchSelect
              excludeIds={[currentPerson.id, ...(oldPersonId ? [oldPersonId] : [])]}
              onSelect={handleSelectExisting}
              isLoading={isSaving}
            />
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
}


// ─── FamilySection ────────────────────────────────────────────────────────────

interface OwnFamilySectionProps {
  family: Family;
  spouse: Person | null;
  children: Array<{ person: Person; familyId: string }>;
  currentPerson: Person;
  canEdit: boolean;
  index: number;
  onAddChild: (familyId: string) => void;
  onEditSpouse: (familyId: string, spouseId: string) => void;
  onDeleteSpouse: (familyId: string, spouseName: string) => void;
  onEditChild: (familyId: string, childId: string) => void;
  onDeleteChild: (familyId: string, childId: string, childName: string) => void;
}

function OwnFamilySection({
  family,
  spouse,
  children,
  currentPerson,
  canEdit,
  index,
  onAddChild,
  onEditSpouse,
  onDeleteSpouse,
  onEditChild,
  onDeleteChild,
}: OwnFamilySectionProps) {
  const spouseLabel = currentPerson.gender === 1 ? 'Vợ' : 'Chồng';

  return (
    <div className="space-y-3">
      {index > 0 && <Separator />}

      {/* Spouse */}
      <div>
        <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1">
          {spouseLabel}
          {family.marriage_date && (
            <span className="ml-2 normal-case font-normal">
              (kết hôn {family.marriage_date})
            </span>
          )}
        </p>
        {spouse ? (
          <PersonLink 
            person={spouse} 
            actions={
              <RelationActions
                personId={spouse.id}
                canEdit={canEdit}
                onEdit={() => onEditSpouse(family.id, spouse.id)}
                onDelete={() => onDeleteSpouse(family.id, spouse.display_name)}
              />
            }
          />
        ) : (
          <div className="flex items-center justify-between px-2">
            <p className="text-sm text-muted-foreground">Chưa rõ</p>
            {canEdit && (
              <Button variant="ghost" size="sm" className="h-7 px-2 text-xs" onClick={() => onEditSpouse(family.id, '')}>
                <Plus className="h-3 w-3 mr-1" />
                Thêm {spouseLabel.toLowerCase()}
              </Button>
            )}
          </div>
        )}
      </div>

      {/* Children */}
      <div>
        <div className="flex items-center justify-between mb-1">
          <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
            Con cái ({children.length})
          </p>
          {canEdit && (
            <Button
              variant="ghost"
              size="sm"
              className="h-6 text-xs px-2"
              onClick={() => onAddChild(family.id)}
            >
              <Plus className="h-3 w-3 mr-1" />
              Thêm con
            </Button>
          )}
        </div>
        {children.length > 0 ? (
          <div className="space-y-0.5">
            {children.map(({ person: child, familyId }) => (
              <PersonLink 
                key={child.id} 
                person={child} 
                actions={
                  <RelationActions
                    personId={child.id}
                    canEdit={canEdit}
                    onEdit={() => onEditChild(familyId, child.id)}
                    onDelete={() => onDeleteChild(familyId, child.id, child.display_name)}
                  />
                }
              />
            ))}
          </div>
        ) : (
          <p className="text-sm text-muted-foreground px-2">Chưa có con</p>
        )}
      </div>
    </div>
  );
}


// ─── FamilyRelationsCard ──────────────────────────────────────────────────────

interface FamilyRelationsCardProps {
  person: Person;
  canEdit: boolean;
}

export function FamilyRelationsCard({ person, canEdit }: FamilyRelationsCardProps) {
  const { data: relations, isLoading, refetch } = usePersonRelations(person.id);
  const ownFamilies = relations?.ownFamilies || [];

  // Merge families with the same spouse to avoid duplicate entries (e.g. if children were added across multiple family records)
  const mergedOwnFamilies = useMemo(() => {
    if (!ownFamilies.length) return [];
    
    const groups: Map<string, {
      family: Family;
      spouse: Person | null;
      children: Array<{ person: Person; familyId: string }>;
    }> = new Map();
    
    ownFamilies.forEach(entry => {
      const spouseId = entry.spouse?.id;
      // Key by spouse ID, or by family ID if spouse is unknown
      const key = spouseId || `unknown-${entry.family.id}`;
      
      if (groups.has(key)) {
        const group = groups.get(key)!;
        group.children.push(...entry.children.map(c => ({ person: c, familyId: entry.family.id })));
      } else {
        groups.set(key, {
          family: entry.family,
          spouse: entry.spouse,
          children: entry.children.map(c => ({ person: c, familyId: entry.family.id }))
        });
      }
    });
    
    const result = Array.from(groups.values());
    result.forEach(group => {
      // Sort children by birth year for a cleaner display
      group.children.sort((a, b) => (a.person.birth_year || 9999) - (b.person.birth_year || 9999));
    });
    
    return result;
  }, [ownFamilies]);

  const [dialogMode, setDialogMode] = useState<DialogMode | null>(null);
  const [targetFamilyId, setTargetFamilyId] = useState<string | undefined>();
  const [isUpdate, setIsUpdate] = useState(false);
  const [oldPersonId, setOldPersonId] = useState<string | undefined>();

  const removeChildMutation = useRemoveChildFromFamily();
  const updateFamilyMutation = useUpdateFamily();

  const openAddFatherDialog = () => {
    setDialogMode('father');
    setTargetFamilyId(undefined);
    setIsUpdate(false);
    setOldPersonId(undefined);
  };

  const openAddMotherDialog = () => {
    setDialogMode('mother');
    setTargetFamilyId(undefined);
    setIsUpdate(false);
    setOldPersonId(undefined);
  };

  const openAddSpouseDialog = () => {
    setDialogMode('spouse');
    setTargetFamilyId(undefined);
    setIsUpdate(false);
    setOldPersonId(undefined);
  };

  const openAddChildDialog = (familyId: string) => {
    setDialogMode('child');
    setTargetFamilyId(familyId);
    setIsUpdate(false);
    setOldPersonId(undefined);
  };

  const openUpdateRelationDialog = (mode: DialogMode, familyId: string, personId: string) => {
    setDialogMode(mode);
    setTargetFamilyId(familyId);
    setIsUpdate(true);
    setOldPersonId(personId);
  };

  const closeDialog = () => {
    setDialogMode(null);
    setTargetFamilyId(undefined);
    setIsUpdate(false);
    setOldPersonId(undefined);
  };

  const handleDeleteChild = async (familyId: string, childId: string, childName: string) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa ${childName} khỏi danh sách con của ${person.display_name}?`)) {
      return;
    }

    try {
      await removeChildMutation.mutateAsync({ familyId, personId: childId });
      toast.success(`Đã xóa ${childName}`);
      refetch();
    } catch (err) {
      toast.error('Lỗi khi xóa: ' + (err instanceof Error ? err.message : ''));
    }
  };

  const handleDeleteRelation = async (mode: 'father' | 'mother' | 'spouse', familyId: string, name: string) => {
    const label = mode === 'father' ? 'cha' : (mode === 'mother' ? 'mẹ' : (person.gender === 1 ? 'vợ' : 'chồng'));
    if (!confirm(`Bạn có chắc chắn muốn xóa ${name} khỏi quan hệ ${label} của ${person.display_name}?`)) {
      return;
    }

    try {
      const field = mode === 'father' ? 'father_id' : (mode === 'mother' ? 'mother_id' : (person.gender === 1 ? 'mother_id' : 'father_id'));
      await updateFamilyMutation.mutateAsync({
        id: familyId,
        input: { [field]: null },
      });
      toast.success(`Đã xóa quan hệ ${label}`);
      refetch();
    } catch (err) {
      toast.error('Lỗi khi xóa: ' + (err instanceof Error ? err.message : ''));
    }
  };


  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Users className="h-4 w-4" />
            Quan hệ gia đình
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <Skeleton className="h-8 w-full" />
          <Skeleton className="h-8 w-3/4" />
          <Skeleton className="h-8 w-1/2" />
        </CardContent>
      </Card>
    );
  }

  const { parentFamily } = relations || { parentFamily: null };

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <Users className="h-4 w-4" />
              Quan hệ gia đình
            </CardTitle>
            {canEdit && (
              <Button variant="outline" size="sm" onClick={openAddSpouseDialog}>
                <Plus className="h-4 w-4 mr-1" />
                Thêm vợ/chồng
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Parents section */}
          {parentFamily ? (
            <div className="space-y-2">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1">
                    Cha
                  </p>
                  {parentFamily.father ? (
                    <PersonLink 
                      person={parentFamily.father} 
                      actions={
                        <RelationActions
                          personId={parentFamily.father.id}
                          canEdit={canEdit}
                          onEdit={() => openUpdateRelationDialog('father', parentFamily.family.id, parentFamily.father!.id)}
                          onDelete={() => handleDeleteRelation('father', parentFamily.family.id, parentFamily.father!.display_name)}
                        />
                      }
                    />
                  ) : (
                    <div className="flex items-center justify-between px-2">
                      <p className="text-sm text-muted-foreground">Chưa rõ</p>
                      {canEdit && (
                        <Button variant="ghost" size="sm" className="h-7 px-2 text-xs" onClick={() => openUpdateRelationDialog('father', parentFamily.family.id, '')}>
                          <Plus className="h-3 w-3 mr-1" />
                          Thêm cha
                        </Button>
                      )}
                    </div>
                  )}
                </div>
                <div>
                  <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1">
                    Mẹ
                  </p>
                  {parentFamily.mother ? (
                    <PersonLink 
                      person={parentFamily.mother} 
                      actions={
                        <RelationActions
                          personId={parentFamily.mother.id}
                          canEdit={canEdit}
                          onEdit={() => openUpdateRelationDialog('mother', parentFamily.family.id, parentFamily.mother!.id)}
                          onDelete={() => handleDeleteRelation('mother', parentFamily.family.id, parentFamily.mother!.display_name)}
                        />
                      }
                    />
                  ) : (
                    <div className="flex items-center justify-between px-2">
                      <p className="text-sm text-muted-foreground">Chưa rõ</p>
                      {canEdit && (
                        <Button variant="ghost" size="sm" className="h-7 px-2 text-xs" onClick={() => openUpdateRelationDialog('mother', parentFamily.family.id, '')}>
                          <Plus className="h-3 w-3 mr-1" />
                          Thêm mẹ
                        </Button>
                      )}
                    </div>
                  )}
                </div>
              </div>

              {/* Siblings */}
              {parentFamily.siblings.length > 0 && (
                <div>
                  <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1">
                    Anh/Chị/Em ({parentFamily.siblings.length})
                  </p>
                  <div className="space-y-0.5">
                    {parentFamily.siblings.map((sib) => (
                      <PersonLink 
                        key={sib.id} 
                        person={sib} 
                        actions={
                          <RelationActions
                            personId={sib.id}
                            canEdit={canEdit}
                            onEdit={() => openUpdateRelationDialog('child', parentFamily.family.id, sib.id)}
                            onDelete={() => handleDeleteChild(parentFamily.family.id, sib.id, sib.display_name)}
                          />
                        }
                      />
                    ))}
                  </div>
                </div>
              )}

              <Separator />
            </div>
          ) : (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Cha/Mẹ
                </p>
                {canEdit && (
                  <div className="flex gap-2">
                    <Button variant="ghost" size="sm" className="h-7 px-2 text-xs" onClick={openAddFatherDialog}>
                      <Plus className="h-3 w-3 mr-1" />
                      Thêm cha
                    </Button>
                    <Button variant="ghost" size="sm" className="h-7 px-2 text-xs" onClick={openAddMotherDialog}>
                      <Plus className="h-3 w-3 mr-1" />
                      Thêm mẹ
                    </Button>
                  </div>
                )}
              </div>
              <p className="text-sm text-muted-foreground px-2">Chưa có thông tin cha/mẹ</p>
            </div>
          )}

          {/* Own families (spouse + children) */}
          {mergedOwnFamilies.length > 0 ? (
            <div className="space-y-4">
              {mergedOwnFamilies.map((group, idx) => (
                <OwnFamilySection
                  key={group.spouse?.id || group.family.id}
                  family={group.family}
                  spouse={group.spouse}
                  children={group.children}
                  currentPerson={person}
                  canEdit={canEdit}
                  index={idx}
                  onAddChild={openAddChildDialog}
                  onEditSpouse={openUpdateRelationDialog.bind(null, 'spouse')}
                  onDeleteSpouse={(fid, name) => handleDeleteRelation('spouse', fid, name)}
                  onEditChild={openUpdateRelationDialog.bind(null, 'child')}
                  onDeleteChild={handleDeleteChild}
                />
              ))}
            </div>
          ) : (
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Chưa có gia đình riêng</p>
              {canEdit && (
                <p className="text-xs text-muted-foreground">
                  Thêm vợ/chồng để tạo gia đình, sau đó có thể thêm con.
                </p>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Dialog */}
      {dialogMode && (
        <RelationDialog
          open={true}
          onClose={closeDialog}
          mode={dialogMode}
          currentPerson={person}
          targetFamilyId={targetFamilyId}
          isUpdate={isUpdate}
          oldPersonId={oldPersonId}
          onSuccess={() => refetch()}
        />
      )}
    </>
  );
}

