import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { CategoryService } from '../services/category.service';
import { CreateCategoryDto } from '../dtos/category.dto';
import { Role } from 'src/common/enums/roles.enum';
import { Roles } from 'src/common/decorators/roles.decorator';

@Controller('categories')
export class CategoryController {
  constructor(private readonly categoryService: CategoryService) {}

  @Post('create')
  @Roles(Role.Admin)
  create(@Body() createCategoryDto: CreateCategoryDto) {
    return this.categoryService.create(createCategoryDto);
  }

  @Get('all')
  findAll() {
    return this.categoryService.findAll();
  }

  @Get('view/:id')
  findOne(@Param('id') id: string) {
    return this.categoryService.findOne(id);
  }
}
